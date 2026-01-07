# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Kustomer::SyncWorker do
  let(:worker) { described_class.new }
  let(:kustomer_entity_id) { 0 }

  before do
    allow(Sentry).to receive(:capture_exception_with_message)
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:info)
  end

  describe '#perform' do
    subject(:perform) { worker.perform(kustomer_entity_id) }

    it 'fails' do
      expect { perform }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'sends the error on Sentry' do
      expect { perform }.to raise_error(ActiveRecord::RecordNotFound)

      expect(Sentry).to have_received(:capture_exception_with_message)
    end

    context 'when kustomer_entity exists' do
      let(:kustomer_entity) { create(:kustomer_order) }
      let(:kustomer_entity_id) { kustomer_entity.id }
      let(:success) { true }
      let(:result) { instance_double(RestClient::Response, body: 'body', code: 200) }
      let(:interactor) do
        # rubocop:disable RSpec/VerifiedDoubles
        double(Interactor::Context, success?: success, result: result, rate_limit_error: nil, error: interactor_error)
        # rubocop:enable RSpec/VerifiedDoubles
      end
      let(:interactor_error) {}

      before { allow(Maisonette::Kustomer::SyncInteractor).to receive(:call).and_return(interactor) }

      it 'calls sync kustomer interactor' do
        perform

        expect(Maisonette::Kustomer::SyncInteractor).to have_received(:call).with(kustomer_entity: kustomer_entity)
        expect(Rails.logger).to have_received(:info).with(
          I18n.t(
            'spree.kustomer.sync_success',
            kustomer_entity_id: kustomer_entity.id
          )
        )
      end

      it 'marks the record as in_sync' do
        allow(Maisonette::Kustomer::Order).to receive(:with_advisory_lock) do |_, &block|
          expect(kustomer_entity.reload).to have_attributes(sync_status: 'processing')

          block.call
        end

        perform

        expect(kustomer_entity.reload).to have_attributes(sync_status: 'in_sync')
      end

      it 'updates the last_* attributes' do
        perform

        expect(kustomer_entity.reload).to have_attributes(
          last_response_body: 'body',
          last_response_code: '200',
          last_message: nil
        )
      end

      context 'when interactor fails' do
        let(:success) { false }
        let(:result) { instance_double(RestClient::Response, body: 'body', code: 600) }

        it 'marks the record as out_of_sync' do
          allow(Maisonette::Kustomer::Order).to receive(:with_advisory_lock) do |_, &block|
            expect(kustomer_entity.reload).to have_attributes(sync_status: 'processing')

            block.call
          end

          perform

          expect(kustomer_entity.reload).to have_attributes(sync_status: 'out_of_sync')
          expect(Rails.logger)
            .to have_received(:error).with(
              I18n.t(
                'spree.kustomer.sync_error',
                kustomer_entity_id: kustomer_entity.id,
                error_message: ''
              )
            )
        end

        context 'when the call fails for rate limitation' do
          let(:success) { false }
          let(:rate_limit_error) { Time.current + 1.minute }
          let(:interactor) do
            # rubocop:disable RSpec/VerifiedDoubles
            double(Interactor::Context,
                   success?: success,
                   result: result,
                   rate_limit_error: rate_limit_error,
                   error: nil)
            # rubocop:enable RSpec/VerifiedDoubles
          end

          before { allow(described_class).to receive(:perform_in) }

          it 're_enqueue the worker in 1 minute' do
            perform

            expect(kustomer_entity.reload).to have_attributes(sync_status: 'out_of_sync')
            expect(described_class).to have_received(:perform_in).with(1.minute, kustomer_entity_id)
          end
        end

        context 'when the interactor has no result' do
          let(:result) {}

          it 'marks the record as out_of_sync' do
            perform

            expect(kustomer_entity.reload).to have_attributes(sync_status: 'out_of_sync', last_result: 'failed')
            expect(Rails.logger)
              .to have_received(:error).with(
                I18n.t(
                  'spree.kustomer.sync_error',
                  kustomer_entity_id: kustomer_entity.id,
                  error_message: ''
                )
              )
          end
        end

        context 'when interactor error message exists' do
          let(:interactor_error) { 'something went wrong' }

          it 'logs the error message' do
            perform

            expect(Rails.logger)
              .to have_received(:error).with(
                I18n.t(
                  'spree.kustomer.sync_error',
                  kustomer_entity_id: kustomer_entity.id,
                  error_message: interactor_error
                )
              )
          end

        end
      end

      context 'when interactor raises an exception' do
        let(:kustomer_entity) { create(:kustomer_order, kustomer_entity_attributes) }
        let(:message) { "undefined method `method_name' for #<Maisonette::Kustomer::SyncInteractor:0x000007ffc>" }
        let(:exception) { NoMethodError.new(message) }
        let(:kustomer_entity_attributes) do
          {
            sync_status: 'in_sync',
            last_request_payload: {},
            last_result: 'success',
            last_message: '',
            last_response_body: '{ success: true }',
            last_response_code: '200',
          }
        end
        let(:expected_kustomer_entity_attributes) do
          {
            sync_status: 'out_of_sync',
            last_request_payload: {},
            last_result: 'failed',
            last_message: "undefined method `method_name' for #<Maisonette::Kustomer::SyncInteractor:0x000007ffc>",
            last_response_body: nil,
            last_response_code: nil,
          }
        end

        before do
          allow(Maisonette::Kustomer::SyncInteractor).to receive(:call).and_raise(exception)
          allow(Sentry).to receive(:capture_exception_with_message)
          allow(Rails.logger).to receive(:error)
        end

        it 'sends error on sentry' do
          expect { perform }.to raise_error(NoMethodError)

          expect(Sentry).to have_received(:capture_exception_with_message).with(
            exception, extra: { kustomer_entity_id: kustomer_entity_id }
          )
        end

        it 'logs the error' do
          expect { perform }.to raise_error(NoMethodError)

          expect(Rails.logger).to have_received(:error).with(
            I18n.t('spree.kustomer.sync_error', kustomer_entity_id: kustomer_entity.id, error_message: message)
          )
        end

        it 'update the kustomer_entity attributes with the error' do
          expect(kustomer_entity).to have_attributes kustomer_entity_attributes

          expect { perform }.to raise_error(NoMethodError)

          expect(kustomer_entity.reload).to have_attributes(
            sync_status: 'out_of_sync',
            last_request_payload: {},
            last_result: 'failed',
            last_message: message,
            last_response_body: nil,
            last_response_code: nil
          )
        end
      end

      context 'when record is updated in the meanwhile' do
        before do
          allow(described_class).to receive(:perform_in)
          allow(described_class).to receive(:perform_async)
          allow(Maisonette::Kustomer::SyncInteractor).to receive(:call) do
            kustomer_entity.update(sync_status: :out_of_sync)
            interactor
          end
        end

        it 're-enqueues the worker' do
          perform

          expect(described_class).to have_received(:perform_in).with(5.seconds, kustomer_entity_id)
          expect(described_class).to have_received(:perform_async).with(kustomer_entity_id)
        end
      end
    end
  end
end
