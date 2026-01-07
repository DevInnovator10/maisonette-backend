# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::UpdateShipmentTrackingInteractor, mirakl: true do
  describe '#call' do
    let(:interactor) { described_class.call mirakl_order: mirakl_order }
    let(:mirakl_order) do
      build_stubbed :mirakl_order,
                    state: :SHIPPING,
                    shipping_tracking: tracking_number,
                    shipping_carrier_code: shipping_carrier_code,
                    shipping_tracking_url: tracking_url
    end
    let(:shipment) do
      instance_double Spree::Shipment,
                      update: true,
                      cartons: cartons
    end
    let(:tracking_number) { nil }
    let(:shipping_carrier_code) { nil }
    let(:tracking_url) { nil }
    let(:cartons) { [] }

    # rubocop:disable RSpec/VerifiedDoubles
    let(:context) { double Interactor::Context, success?: true, tracker: tracker }
    let(:tracker) { double ::EasyPost::Tracker, carrier: easypost_carrier }
    # rubocop:enable RSpec/VerifiedDoubles

    let(:easypost_carrier) { 'ups' }

    context 'when it is successful' do
      before do
        allow(mirakl_order).to receive_messages(shipment: shipment)
        allow(Easypost::CreateTrackerInteractor).to receive(:call).and_return(context)

        interactor
      end

      context 'when only a tracking number and url is supplied' do
        let(:tracking_number) { '12340987' }
        let(:shipping_carrier_code) { 'fedex' }
        let(:tracking_url) { 'www.some_tracking.io?tracking_id=12340987' }

        context 'when the shipping_carrier_code exist' do
          let(:shipping_carrier_code) { 'fedex' }

          it 'updates the tracking number and carrier code on the shipment' do
            expect(shipment).to have_received(:update).with(tracking: tracking_number,
                                                            shipping_carrier_code: shipping_carrier_code)
          end

          it 'calls Easypost::CreateTrackerInteractor' do
            expect(Easypost::CreateTrackerInteractor).to have_received(:call).with(tracking_code: tracking_number,
                                                                                   carrier: shipping_carrier_code,
                                                                                   mirakl_order: mirakl_order)
          end

          # rubocop:disable RSpec/NestedGroups
          context 'when Easypost::CreateTrackerInteractor returns a tracker' do
            context 'when the tracker contains a carrier' do
              it 'updates the shipment carrier' do
                expect(shipment).to have_received(:update).with(shipping_carrier_code: easypost_carrier)
              end
            end

            context 'when the tracker does not contain a carrier' do
              let(:easypost_carrier) { nil }

              it 'does not update the shipment carrier' do
                expect(shipment).not_to have_received(:update).with(shipping_carrier_code: easypost_carrier)
              end
            end
          end
          # rubocop:enable RSpec/NestedGroups

          context 'when Easypost::CreateTrackerInteractor does not return a tracker' do
            let(:tracker) { nil }

            it 'does not update the shipment carrier' do
              expect(shipment).not_to have_received(:update).with(shipping_carrier_code: easypost_carrier)
            end
          end

          context 'when cartons exist' do
            let(:cartons) { [carton_1] }
            let(:carton_1) { instance_double Spree::Carton, update: true }

            it 'updates the carton with the tracking number and carrier code' do
              expect(carton_1).to have_received(:update).with(tracking: tracking_number,
                                                              shipping_carrier_code: shipping_carrier_code)
            end
          end
        end

        context 'when the shipping_carrier_code is nil' do
          let(:shipping_carrier_code) {}

          it 'updates the tracking number and override tracking url on the shipment' do
            expect(shipment).to have_received(:update).with(tracking: tracking_number,
                                                            override_tracking_url: tracking_url)
          end

          it 'calls Easypost::CreateTrackerInteractor' do
            expect(Easypost::CreateTrackerInteractor).to have_received(:call).with(tracking_code: tracking_number,
                                                                                   carrier: nil,
                                                                                   mirakl_order: mirakl_order)
          end

          context 'when cartons exist' do
            let(:cartons) { [carton_1] }
            let(:carton_1) { instance_double Spree::Carton, update: true }

            it 'updates the carton with the tracking number and override tracking url' do
              expect(carton_1).to have_received(:update).with(tracking: tracking_number,
                                                              override_tracking_url: tracking_url)
            end
          end
        end
      end

      context 'when the tracking number is not supplied' do
        it 'does not update the tracking number on the shipment' do
          expect(shipment).not_to have_received(:update)
        end

        it 'does not call Easypost::CreateTrackerInteractor' do
          expect(Easypost::CreateTrackerInteractor).not_to have_received(:call)
        end

        context 'when cartons exist' do
          let(:cartons) { [carton_1] }
          let(:carton_1) { instance_double Spree::Carton, update: true }

          it 'does not update the carton' do
            expect(carton_1).not_to have_received(:update)
          end
        end
      end
    end

    context 'when an error is thrown' do
      let(:interactor) { described_class.new mirakl_order: mirakl_order }
      let(:exception) { StandardError.new 'some error' }

      before do
        allow(interactor).to receive_messages(rescue_and_capture: false)
        allow(interactor).to receive(:tracking_code).and_raise(exception)

        interactor.call
      end

      it 'does not fail the interactor' do
        expect(interactor.context).not_to be_failure
      end

      it 'calls rescue_and_capture' do
        expect(interactor).to(
          have_received(:rescue_and_capture).with(exception,
                                                  extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        )
      end
    end
  end
end
