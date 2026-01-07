# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Narvar::Api::Payloads::Order, narvar: true do
  describe '#payload' do
    context 'without a Narvar order' do
      subject { described_class.new(nil).payload }

      it { is_expected.to be_empty }
    end

    context 'with a Narvar order' do
      let(:order) { build_stubbed(:order_ready_to_ship, :with_line_items, :narvar_updated, number: 'R12345678') }
      let(:payload) { described_class.new(order).payload }

      it 'has a payload with an order_info' do
        expect(payload).to match hash_including :order_info
      end

      it 'has a payload with an order_number in order_info' do
        expect(payload).to match hash_including order_info: hash_including(order_number: order.number)
      end

      it 'has a payload with order_items in order_info' do
        expect(payload).to match hash_including order_info: hash_including(:order_items)
      end

      it 'has a payload with billing in order_info' do
        expect(payload).to match hash_including order_info: hash_including(:billing)
      end

      it 'has a payload with customer in order_info' do
        expect(payload).to match hash_including order_info: hash_including(:customer)
      end

      it 'has a payload with 1 order item in order_info' do
        expect(payload.dig(:order_info, :order_items)&.size).to be_positive
      end

      context 'with item data' do
        let(:discount_adjustment) { build_stubbed(:adjustment, amount: -0.02) }
        let(:item_data) { payload.dig(:order_info, :order_items)[0] }

        before do
          type = create :option_type, name: 'Color', presentation: 'Color'
          option = build_stubbed :option_value, name: 'Opt 1', presentation: 'Opt 1', option_type: type
          type2 = create :option_type, name: 'Test', presentation: 'Test'
          option2 = build_stubbed :option_value, name: 'Opt 2', presentation: 'Opt 2', option_type: type2
          order.line_items.first.variant.option_values << option
          order.line_items.first.variant.option_values << option2
          order.line_items.first.final_sale = false
          order.line_items.first.price = BigDecimal(65)
          order.line_items.first.adjustments << discount_adjustment
          order.line_items.first.quantity = 1
        end

        it 'has hash with color key and corresponding value' do
          expect(item_data).to match hash_including color: 'Opt 1'
        end

        it 'has size key' do
          expect(item_data).to match hash_including :size
        end

        it 'has style key' do
          expect(item_data).to match hash_including :style
        end

        it 'has attributes key and corresponding value' do
          expect(item_data).to match hash_including attributes: hash_including(:test)
        end

        it 'has attributes key that does not include color key' do
          expect(item_data).not_to match hash_including attributes: hash_including(:color)
        end

        context 'when item_data.final_sale is false' do
          context 'when total_before_tax/quantity is greater than customer return fee' do
            it 'has is_final_sale key with corresponding value set to false' do
              expect(item_data).to match hash_including is_final_sale: false
            end
          end

          context 'when total_before_tax/quantity is less than customer return fee' do
            before do
              order.line_items.first.price = BigDecimal(4)
            end

            it 'has is_final_sale key with corresponding value set to true' do
              expect(item_data).to match hash_including is_final_sale: true
            end
          end
        end

        context 'when item_data.final_sale is true' do
          before do
            order.line_items.first.final_sale = true
          end

          it 'has is_final_sale key with corresponding value set to true' do
            expect(item_data).to match hash_including is_final_sale: true
          end
        end
      end
    end

    context 'with a gifted Narvar order' do
      let(:order) do
        build_stubbed(
          :order_ready_to_ship,
          :with_line_items,
          :narvar_updated,
          number: 'R12345678',
          is_gift: true,
          email: 'gift.giver@gmail.com',
          gift_email: 'gift.receiver@narvar.com',
          gift_message: 'This is a wonderful gift for you!'
        )
      end
      let(:payload) { described_class.new(order).payload }
      let(:payload_billing_email) { payload.dig(:order_info, :billing, :billed_to, :email) }
      let(:payload_customer_email) { payload.dig(:order_info, :customer, :email) }

      it 'has a payload with the gift receiver email' do
        expect(payload_billing_email).to eq order.gift_email
        expect(payload_customer_email).to eq order.gift_email
      end

      context 'without a gift receiver email' do
        it 'has a payload with the original purchaser email' do
          order.gift_email = nil
          expect(payload_billing_email).to eq order.email
          expect(payload_customer_email).to eq order.email
        end
      end
    end
  end
end
