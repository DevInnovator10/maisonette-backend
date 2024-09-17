# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'stale price coordinator' do |stale_price, actual_price|
  %w[cart address delivery].each do |state|
    context "when order is in state #{state}" do
      before { order.update(state: state) }

      it 'updates the line_item prices' do
        expect { order.next! }.to(
          change { line_item.reload.price }.from(stale_price).to(actual_price)
            .and(change { line_item.reload.cost_price }.from(stale_price).to(actual_price))
        )
      end

      it 'updates the order total' do
        expect { order.next! }.to(change { order.reload.total })
      end
    end
  end

  %w[confirm].each do |state|
    context "when order is in state #{state}" do
      subject(:advance!) { state == 'payment' ? order.next! : order.complete! }

      before { order.update(state: state) }

      it 'raises a StalePriceError exception' do
        expect { advance! }.to raise_error(Spree::Order::PriceNotStale::StalePriceError)
      end

      it 'updates the line_item prices' do
        expect do
          advance! rescue Spree::Order::PriceNotStale::StalePriceError # rubocop:disable Style/RescueModifier
        end.to change { line_item.reload.price }.from(stale_price).to(actual_price)
                                                .and change { line_item.reload.cost_price }
          .from(stale_price).to(actual_price)
      end

      it 'invalidates all payments' do
        expect do
          advance! rescue Spree::Order::PriceNotStale::StalePriceError # rubocop:disable Style/RescueModifier
        end.to change { order.payments.valid.empty? }.from(false).to(true)
      end

      it 'adds an error on order' do
        advance! rescue Spree::Order::PriceNotStale::StalePriceError # rubocop:disable Style/RescueModifier

        expect(order.errors.to_h).to include(
          line_items: "The price has changed for the following item(s): #{variant.descriptive_name}"
        )
      end
    end
  end
end

RSpec.describe Spree::Order::PriceNotStale, type: :model do
  describe '#complete!' do
    subject { order.complete! }

    let(:line_item) { order.line_items.first }
    let(:first_vendor) { create(:vendor, stock_location: stock_location) }
    let(:second_vendor) { create(:vendor, stock_location: stock_location2) }
    let(:vendor_prices) { [{ vendor: first_vendor, amount: 10 }, { vendor: second_vendor, amount: 15 }] }
    let(:variant) do
      create(
        :variant,
        :with_multiple_prices,
        vendor_prices: vendor_prices,
        offer_settings: [offer_setting]
      ).tap do |variant|
        variant.stock_items.first.set_count_on_hand(10)
      end
    end
    let(:stock_location) { create(:stock_location, propagate_all_variants: true) }
    let(:stock_location2) { create(:stock_location, propagate_all_variants: true) }
    let(:order) do
      create(
        :order_ready_to_complete,
        stock_location: stock_location,
        line_items_attributes: [{
          price: variant.price_for_vendor(second_vendor, as_money: false).amount,
          vendor: second_vendor,
          variant: variant
        }]
      )
    end
    let(:offer_setting) do
      create(:offer_settings,
             vendor_id: second_vendor.id,

             cost_price: offer_setting_cost_price,
             monogram_price: offer_setting_monogram_price)
    end
    let(:offer_setting_cost_price) { 15 }
    let(:offer_setting_monogram_price) {}

    context 'when a variant is added to cart' do
      it { is_expected.to be_truthy }

      context 'when there are at least one line_item with different price from the variant price' do
        before do
          price = order.variants.first.price_for_vendor(second_vendor, as_money: false)
          offer_setting.update(cost_price: 1)
          price.update(amount: 1)
        end

        it_behaves_like 'stale price coordinator', 15, 1
      end
    end

    context 'when a price on sale is added on the cart', :freeze_time do
      before do
        stock_location
        price = variant.price_for_vendor(second_vendor, as_money: false)

        price.new_sale(
          14,
          start_at: nil,
          end_at: DateTime.tomorrow.in_time_zone,
          enabled: true
        ).save
        price.reload

        price.active_sale.update(cost_price: 14)
        order
      end

      it { is_expected.to be_truthy }

      context 'when the sale expires' do
        subject { -> { order.complete! } }

        before do
          Timecop.travel(DateTime.now.in_time_zone + 2.days)
        end

        it_behaves_like 'stale price coordinator', 14, 15
      end
    end

    context 'when order advance from cart to complete' do
      before do
        allow(order).to receive(:ensure_prices_not_stale).and_return(true)
        allow(order).to receive(:validate_payment_required).and_return(true)
        allow(order).to receive(:fraud_validation).and_return(true)
        Spree::StockItem.all.each { |si| si.set_count_on_hand(11) }
      end

      it 'calls ensure_line_items_present at any transition' do
        order.update(state: :cart)

        expect do
          order.contents.advance
          order.complete!
        end.to change(order, :state).from('cart').to('complete')

        expect(order).to have_received(:ensure_prices_not_stale).exactly(5).times
        expect(order).to have_received(:validate_payment_required).once
        expect(order).to have_received(:fraud_validation).once
      end
    end

    context 'when order is completed' do

      let(:order) do
        create(
          :completed_order_with_totals,
          stock_location: stock_location,
          line_items_attributes: [{
            price: variant.price_for_vendor(second_vendor, as_money: false).amount,
            vendor: second_vendor,
            variant: variant
          }]
        )
      end

      before do
        allow(order).to receive(:ensure_prices_not_stale).and_return(true)
        Spree::StockItem.all.each { |si| si.set_count_on_hand(11) }
      end

      it 'calls ensure_line_items_present at any transition' do
        expect do
          order.cancel!
        end.to change(order, :state).from('complete').to('canceled')

        expect do
          order.resume!
        end.to change(order, :state).from('canceled').to('resumed')

        expect do
          order.authorize_return!
        end.to change(order, :state).from('resumed').to('awaiting_return')

        expect(order).not_to have_received(:ensure_prices_not_stale)
      end
    end

    context 'when there is a monogram' do
      let(:monogram) { instance_double Spree::LineItemMonogram, price: 5, id: 1 }
      let(:offer_setting_monogram_price) { 5 }

      before do
        allow(line_item).to receive_messages(monogram: monogram,
                                             set_pricing_attributes: true,
                                             offer_settings: offer_setting)
        line_item.update(price: line_item.price + monogram.price)
        order.update(state: :address)
      end

      context "when the price doesn't change" do
        it 'does not update the line item price' do
          order.next!
          expect(line_item).not_to have_received(:set_pricing_attributes).with(force_update: true)
        end
      end

      context 'when the price does change' do
        before do
          price = line_item.variant.price_for_vendor(line_item.vendor, as_money: false)
          price.update(amount: 1)
        end

        it 'does update the line item price' do
          order.next!
          expect(line_item).to have_received(:set_pricing_attributes).with(force_update: true)
        end
      end

      context 'when the monogram price changes' do
        let(:offer_setting_monogram_price) { 15 }

        it 'does update the line item price' do
          order.next!
          expect(line_item).to have_received(:set_pricing_attributes).with(force_update: true)
        end
      end
    end

    context 'when the payments sum does not equal the order total' do
      subject(:complete) { order.complete! }

      before do
        order.payments.last.update(amount: order.total - 0.1)
      end

      it 'raises StalePaymentError' do
        expect { complete }.to raise_error(Spree::Order::PriceNotStale::StalePaymentError)
      end

      it 'invalidates all payments' do
        expect do
          complete rescue Spree::Order::PriceNotStale::StalePaymentError # rubocop:disable Style/RescueModifier
        end.to change { order.payments.valid.empty? }.from(false).to(true)
      end

      it 'adds an error on order' do
        complete rescue Spree::Order::PriceNotStale::StalePaymentError # rubocop:disable Style/RescueModifier

        expect(order.errors.to_h).to include(:payment)
      end
    end

    context 'when the payment is already complete' do
      subject(:complete) { order.complete! }

      before do
        order.payments.last.update(state: :completed)
      end

      it 'does not raise any errors' do
        expect { complete }.not_to raise_error
      end
    end

    context 'when one of the variants does not have a price for the vendor before confirm' do
      before { order.update(state: :delivery) }

      it 'raises a OutOfStockError exception if it is out of stock' do
        variant.prices = []
        variant.stock_items.first.set_count_on_hand(0)
        error_message = I18n.t('spree.checkout.errors.out_of_stock_items')

        expect { order.next! }.to raise_error(Spree::Order::PriceNotStale::OutOfStockError, error_message)
      end

      it 'raises a ActiveRecord::RecordInvalid exception' do
        variant.prices = []

        expect { order.next! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '#fraud_validation' do
    subject(:fraud_validation) { order.send(:fraud_validation) }

    let(:order) { build_stubbed :order }
    let(:payments) { class_double Spree::Payment, valid: valid_payments }
    let(:valid_payments) { [payment1] }
    let(:payment1) { instance_double Spree::Payment, invalidate: true }
    let(:forter_context) { instance_double Interactor::Context, success?: validation_success? }
    let(:validation_success?) {}

    before do
      allow(order).to receive(:payment_failed!)
      allow(order).to receive(:payments).and_return(payments)
      allow(Forter::ValidationInteractor).to receive(:call).with(order: order).and_return(forter_context)
    end

    context 'when validation is successful' do
      let(:validation_success?) { true }

      it 'returns true' do
        expect(fraud_validation).to eq true
      end
    end

    context 'when validation is not successful' do
      let(:validation_success?) { false }

      it 'returns false' do
        expect(fraud_validation).to eq false
      end

      it 'fails the payment' do
        fraud_validation
        expect(order).to have_received(:payment_failed!)
        expect(payment1).to have_received(:invalidate)
      end
    end

    context 'when something goes wrong' do
      let(:standard_error) { StandardError.new('something went wrong') }

      before do
        allow(Forter::ValidationInteractor).to receive(:call).with(order: order).and_raise(standard_error)
        allow(Sentry).to receive(:capture_exception_with_message)
      end

      it 'returns true' do
        expect(fraud_validation).to eq true
      end

      it 'alerts in Sentry' do
        fraud_validation
        expect(Sentry).to have_received(:capture_exception_with_message).with(standard_error,
                                                                              message: 'Issue with fraud validation',
                                                                              extra: { order: order.attributes })
      end
    end
  end
end
