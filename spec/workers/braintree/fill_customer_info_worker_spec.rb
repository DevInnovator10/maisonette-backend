# frozen_string_literal: true

require 'rails_helper'
require 'mock_redis'

RSpec.describe Braintree::FillCustomerInfoWorker,
               :mock_redis,
               :sidekiq_inline do
  let(:redis) { Redis.new }
  let(:redis_key) { Braintree::FillCustomerInfoWorker::BRAINTREE_CUSTOMER_QUEUE_KEY }

  before do
    redis.set('braintree_customer_info_worker:seconds', 0)
    redis.del(redis_key)

    braintree_customer_queue.each { |id| redis.rpush(redis_key, id) }

    allow(Braintree::FillCustomerInfoInteractor).to receive(:call)
  end

  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    let(:braintree_customer_queue) { [] }

    it 'exits without call the interactor' do
      perform

      expect(Braintree::FillCustomerInfoInteractor).not_to have_received(:call)
    end

    context 'with two braintree customer id into queue' do
      let(:braintree_customer_queue) { ['1', 2] }

      it 'calls the interactor twice' do
        perform

        expect(Braintree::FillCustomerInfoInteractor).to have_received(:call).with(source_id: '1').once
        expect(Braintree::FillCustomerInfoInteractor).to have_received(:call).with(source_id: '2').once
      end
    end

    context 'with time of execution' do
      let(:braintree_customer_queue) { ['1', 2] }

      before { allow(described_class).to receive(:perform_in) }

      context 'when low traffic time', freeze_time: Time.zone.local(2020, 8, 31, 3) do
        it 'calls the next worker shortly' do
          perform

          expect(described_class).to have_received(:perform_in).with(0.0)
        end
      end

      context 'when not in low traffic time', freeze_time: Time.zone.local(2020, 8, 31, 11) do
        it 'calls the next worker tomorrow' do
          perform

          expect(described_class).to have_received(:perform_in).with(Date.tomorrow.beginning_of_day + 3.hours)
        end
      end
    end

    context 'when the Interactor raises an exception' do
      let(:braintree_customer_queue) { ['1', 2] }

      before do
        allow(Braintree::FillCustomerInfoInteractor).to receive(:call).and_raise
        allow(Sentry).to receive(:capture_exception_with_message)
      end

      it 'sends exception to Sentry' do
        perform

        expect(Sentry).to have_received(:capture_exception_with_message).twice
      end

      it 'processes the other customers anyway' do
        perform

        expect(Braintree::FillCustomerInfoInteractor).to have_received(:call).with(source_id: '1').once
        expect(Braintree::FillCustomerInfoInteractor).to have_received(:call).with(source_id: '2').once
      end
    end

    context 'when the Interactor fails' do
      let(:braintree_customer_queue) { ['1', 2] }
      let(:failure_context) do
        double(Interactor::Context, failure?: true, message: 'error message') # rubocop:disable RSpec/VerifiedDoubles
      end

      before do
        allow(Braintree::FillCustomerInfoInteractor).to receive(:call).and_return(failure_context)
        allow(Sentry).to receive(:capture_message)
      end

      it 'sends exception to Sentry' do
        perform

        expect(Sentry).to have_received(:capture_message).with(
          "Customer not updated - SolidusPaypalBraintree::Source(1)\nMessage: error message"
        )
        expect(Sentry).to have_received(:capture_message).with(
          "Customer not updated - SolidusPaypalBraintree::Source(2)\nMessage: error message"
        )
      end

      it 'processes the other customers anyway' do
        perform

        expect(Braintree::FillCustomerInfoInteractor).to have_received(:call).with(source_id: '1').once
        expect(Braintree::FillCustomerInfoInteractor).to have_received(:call).with(source_id: '2').once
      end
    end
  end
end
