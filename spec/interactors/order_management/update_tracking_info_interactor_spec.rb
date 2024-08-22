# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::UpdateTrackingInfoInteractor do
  describe '#call' do
    subject(:interactor) { described_class.call(interactor_context) }

    let(:interactor_context) do
      { tracking: '123456', shipping_carrier_code: 'NEWCODE', override_tracking_url: 'http://tracking.info' }
    end

    context 'when carton and shipments are invalid' do
      before do
        shipment = instance_double(
          Spree::Shipment,
          number: 'SHIP123',
          update: false,
          errors: instance_double(ActiveModel::Errors, full_messages: ['Shipment is invalid'])
        )
        carton = instance_double(
          Spree::Carton,
          update: false,
          shipments: [shipment],
          errors: instance_double(ActiveModel::Errors, full_messages: ['Carton is invalid'])
        )
        allow(Spree::Carton).to receive(:find_by!).and_return(carton)
        allow(Sentry).to receive(:capture_message)
      end

      it { is_expected.to be_failure }

      it 'returns errors messages' do
        expect(interactor.error).to match(
          hash_including(
            carton: ['Carton is invalid'],
            shipments: [{ number: 'SHIP123', errors: ['Shipment is invalid'] }]
          )
        )
      end

      it 'captures message with Sentry' do
        interactor

        expect(Sentry).to have_received(:capture_message).with(
          'OMS Carton tracking info update failed',
          extra: {
            carton: ['Carton is invalid'],
            shipments: [{ number: 'SHIP123', errors: ['Shipment is invalid'] }]
          }
        )
      end
    end

    context 'when carton and shipments are valid' do
      it 'updates the carton' do
        create(:carton, tracking: '123456')

        expect(interactor.carton).to have_attributes(
          tracking: '123456',
          shipping_carrier_code: 'NEWCODE',
          override_tracking_url: 'http://tracking.info'
        )
      end

      it 'updates the shipment' do
        create(:carton, tracking: '123456')

        expect(interactor.shipments.first).to have_attributes(
          tracking: '123456',
          shipping_carrier_code: 'NEWCODE',
          override_tracking_url: 'http://tracking.info'
        )
      end

      context 'when shipping_carrier_code is not provided' do
        let(:interactor_context) { { tracking: '123456', override_tracking_url: 'http://tracking.info' } }

        it 'does not update carton shipping_carrier_code' do
          create(:carton, tracking: '123456', shipping_carrier_code: 'OLDCODE')

          expect(interactor.carton).to have_attributes(
            tracking: '123456',
            shipping_carrier_code: 'OLDCODE',
            override_tracking_url: 'http://tracking.info'
          )
        end

        it 'does not update shipments shipping_carrier_code' do
          carton = create(:carton, tracking: '123456', shipping_carrier_code: 'OLDCODE')
          carton.shipments.first.update!(shipping_carrier_code: 'OLDCODE')

          expect(interactor.shipments.first).to have_attributes(
            tracking: '123456',
            shipping_carrier_code: 'OLDCODE',
            override_tracking_url: 'http://tracking.info'
          )
        end
      end

      context 'when override_tracking_url is not provided' do
        let(:interactor_context) { { tracking: '123456', shipping_carrier_code: 'NEWCODE' } }

        it 'does not update carton override_tracking_url' do
          create(:carton, tracking: '123456', override_tracking_url: 'http://old-tracking.info')

          expect(interactor.carton).to have_attributes(
            tracking: '123456',
            shipping_carrier_code: 'NEWCODE',
            override_tracking_url: 'http://old-tracking.info'
          )
        end

        it 'does not update shipments override_tracking_url' do
          carton = create(:carton, tracking: '123456', override_tracking_url: 'http://old-tracking.info')
          carton.shipments.first.update!(override_tracking_url: 'http://old-tracking.info')

          expect(interactor.shipments.first).to have_attributes(
            tracking: '123456',
            shipping_carrier_code: 'NEWCODE',
            override_tracking_url: 'http://old-tracking.info'
          )
        end
      end
    end
  end
end
