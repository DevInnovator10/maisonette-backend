# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order::EnsureAvailability, type: :model do
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

    context 'when the price related to line_item variant is destroyed' do
      subject(:advance!) { order.state != 'confirm' ? order.next! : order.complete! }

      let(:price) { order.variants.first.price_for_vendor(second_vendor, as_money: false) }

      %w[confirm].each do |state|
        context "when order is in state #{state}" do
          before do
            order.update(state: state)

            price.discard
          end

          # rubocop:disable Style/RescueModifier
          it 'destroyes the line_items' do
            expect(order.line_items.count).to eq 1

            advance! rescue raise_error(Spree::Order::EnsureAvailability::PriceNotFound)

            expect(order.line_items.count).to be_zero
          end

          it 'adds errors on order' do
            advance! rescue raise_error(Spree::Order::EnsureAvailability::PriceNotFound)

            expect(order.errors.to_h).to include(:line_items)
          end

          it 'removes all payments' do
            advance! rescue raise_error(Spree::Order::EnsureAvailability::PriceNotFound)

            expect(order.payments).to be_empty
          end
          # rubocop:enable Style/RescueModifier

          it 'raises PriceNotFound exception' do
            expect { advance! }.to raise_error(Spree::Order::EnsureAvailability::PriceNotFound)
          end
        end
      end

      %w[address].each do |state|
        context "when order is in state #{state}" do
          before do
            order.update(state: state)

            price.discard
          end

          it 'destroyes the line item' do
            expect { advance! }.to change { order.line_items.count }.from(1).to(0)
          end

          it 'recalculate the order total' do
            expect { advance! }.to change(order, :total).by(-line_item.amount)
          end
        end
      end
    end

    context 'when there is insufficient inventory' do
      subject(:advance!) { order.state != 'confirm' ? order.next! : order.complete! }

      let(:variant) do
        create(
          :variant,
          :with_multiple_prices,
          backorder_date: nil,
          vendor_prices: vendor_prices,
          offer_settings: [offer_setting]
        ).tap do |variant|
          variant.stock_items.first.set_count_on_hand(0)
          variant.stock_items.update(backorderable: false)
        end
      end

      %w[address confirm].each do |state|
        context "when order is in state #{state}" do
          before do
            order.update(state: state)
          end

          # rubocop:disable Style/RescueModifier
          it 'adds errors on order' do
            advance! rescue raise_error(Spree::Order::InsufficientStock)

            expect(order.line_items[0].errors.to_h).to include(:quantity)
          end
          # rubocop:enable Style/RescueModifier

          it 'raises PriceNotFound exception' do
            expect { advance! }.to raise_error(Spree::Order::InsufficientStock)
          end
        end
      end
    end
  end

  describe '#ensure_prices_presence' do
    subject(:ensure_prices_presence) { order.send :ensure_prices_presence }

    let(:order) { build_stubbed :order }

    context 'when it is called without a transition' do
      let(:line_item) { instance_double Spree::LineItem, destroy: true }

      before do
        allow(order).to receive_messages(line_items: [line_item])
        allow(order).to receive(:fetch_money).with(line_item).and_return(nil)
      end

      it 'does not error' do
        expect { ensure_prices_presence }.not_to raise_error
      end
    end
  end
end
