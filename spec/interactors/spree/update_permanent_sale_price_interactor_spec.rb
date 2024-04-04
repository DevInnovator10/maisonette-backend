# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::UpdatePermanentSalePriceInteractor do
  describe '#call', freeze_time: true do
    subject(:update_permanent_sale_price) { interactor.call }

    let(:interactor) { described_class.new(offer_settings: offer_settings) }
    let(:offer_settings) { build :offer_settings, permanent_sale_price: permanent_sale_price }
    let(:permanent_sale_price) {}
    let(:sale_prices) { class_double Spree::SalePrice }
    let(:sale_price) do
      instance_double Spree::SalePrice, permanent: true, update!: true, destroy!: true, value: sale_price_value
    end
    let(:sale_price_value) {}
    let(:fixed_amount_sale_price_calculator) { instance_double Spree::Calculator::FixedAmountSalePriceCalculator }

    context 'when it is successful' do
      context 'when the price exists' do
        let(:price) { instance_double Spree::Price, sale_prices: sale_prices, save!: true }

        before do
          allow(offer_settings).to receive_messages(price: price)
          allow(sale_prices).to receive(:find_by).with(permanent: true).and_return(sale_price)
          allow(sale_prices).to receive(:find_or_initialize_by).with(permanent: true).and_return(sale_price)
          allow(Spree::Calculator::FixedAmountSalePriceCalculator).to(
            receive(:new).and_return(fixed_amount_sale_price_calculator)
          )

          update_permanent_sale_price
        end

        context 'when permanent_sale_price is not zero' do
          let(:permanent_sale_price) { 10.5 }

          context 'when the permanent_sale_price is not equal to the current active permanent sale price' do
            let(:sale_price_value) { 11 }

            it 'creates a fixed amount sale price for the permanent_sale_price amount' do
              expect(sale_price).to have_received(:update!).with(enabled: true,
                                                                 value: permanent_sale_price,
                                                                 calculator: fixed_amount_sale_price_calculator,
                                                                 start_at: Time.current)
            end

            it 'triggers markdown update on the price' do
              expect(price).to have_received(:save!)
            end
          end

          context 'when permanent_sale_price is zero or null' do
            let(:permanent_sale_price) {}

            it 'destroys the permanent sale price if it exists' do
              expect(sale_price).to have_received(:destroy!)
            end

            it 'triggers markdown update on the price' do
              expect(price).to have_received(:save!)
            end
          end

          context 'when the permanent_sale_price is equal to the current active permanent sale price' do
            let(:sale_price_value) { 10.5 }

            it 'does not update the sale price' do
              expect(sale_price).not_to have_received(:update!)
            end

            it 'does not trigger markdown update on the price' do
              expect(price).not_to have_received(:save!)
            end
          end
        end
      end

      context 'when price does not exists' do
        let(:price) {}

        before do
          allow(sale_prices).to receive(:find_by)
          allow(sale_prices).to receive(:find_or_initialize_by)

          update_permanent_sale_price
        end

        it 'does nothing' do
          expect(sale_prices).not_to have_received(:find_by)
          expect(sale_prices).not_to have_received(:find_or_initialize_by)
        end
      end
    end

    context 'when it fails' do
      let(:exception) { StandardError.new 'an error!' }

      before do
        allow(offer_settings).to receive(:price).and_raise(exception)
        allow(interactor).to receive(:rescue_and_capture)

        update_permanent_sale_price
      end

      it 'does not raise an exception' do
        expect { update_permanent_sale_price }.not_to raise_exception
      end

      it 'calls rescue_and_capture' do
        expect(interactor).to(
          have_received(:rescue_and_capture).with(exception,
                                                  extra: { offer_settings: offer_settings.attributes })
        )
      end
    end
  end
end
