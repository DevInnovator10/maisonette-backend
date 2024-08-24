# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::AssociateTrackerToReturnAuthorizationInteractor do
  describe '#call' do
    subject(:call) { interactor.call }

    let(:interactor) { described_class.new(authorization: return_authorization) }
    let(:return_authorization) { create :return_authorization }

    context 'when return_authorization does not have tracking_number' do
      before do
        allow(return_authorization).to receive(:tracking_number).and_return(nil)
      end

      it 'does not create easypost_tracker' do
        expect { call }.not_to(change { Easypost::Tracker.count })
      end
    end

    context 'when return_authorization has tracking_number' do
      before do
        allow(return_authorization).to receive(:tracking_number).and_return(tracking_number)
      end

      let(:tracking_number) { 'My-tracking-number' }

      context 'when tracker is successfully registered with easypost' do
        # rubocop:disable RSpec/VerifiedDoubles
        let(:context) { double(Interactor::Context, success?: true, tracker: tracker_from_easypost) }
        let(:tracker_from_easypost) { double(Interactor::Context, status: status) }
        # rubocop:enable RSpec/VerifiedDoubles

        let(:status) { 'pre_transit' }

        before do
          allow(Easypost::CreateTrackerInteractor).to receive(:call).and_return(context)
        end

        it 'creates easypost tracker' do
          expect { call }.to change { Easypost::Tracker.count }.by(1)
        end

        it 'creates an easypost_tracker associated with the authorization' do
          call
          expect(interactor.context.authorization.reload.easypost_tracker).not_to be_nil
        end

        it 'saves the carrier' do
          call
          expect(interactor.context.authorization.reload.easypost_tracker.carrier).to eq interactor.send(:carrier)
        end

        it 'saves the tracking_number' do
          call
          expect(interactor.context.authorization.reload.easypost_tracker.tracking_code).to eq tracking_number
        end

        it 'saves the status' do
          call
          expect(interactor.context.authorization.reload.easypost_tracker.status).to eq status
        end
      end

      context 'when tracker is not successfully registered with easypost' do
        # rubocop:disable RSpec/VerifiedDoubles
        let(:context) { double(Interactor::Context, success?: true, tracker: nil) }
        # rubocop:enable RSpec/VerifiedDoubles

        before do
          allow(Easypost::CreateTrackerInteractor).to receive(:call).and_return(context)
        end

        it 'does not create easypost tracker' do
          expect { call }.not_to(change { Easypost::Tracker.count })
        end
      end
    end
  end
end
