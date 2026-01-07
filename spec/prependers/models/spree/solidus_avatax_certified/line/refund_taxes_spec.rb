# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolidusAvataxCertified::Line::RefundTaxes, type: :model do
  let(:line) { SolidusAvataxCertified::Line.new(order, 'ReturnInvoice', refund) }

  describe '#refund_lines' do
    context 'when the reimbursement has a reimbursement' do
      let(:number) { "#{line_item.id}-LI" }
      let(:reimbursement) { instance_double Spree::Reimbursement }
      let(:refund) { instance_double Spree::Refund }
      let(:user) { create(:user, exemption_number: 'exempt', vat_id: 'vat id') }
      let(:mirakl_order_line_reimbursement) { instance_double Mirakl::OrderLineReimbursement }
      let(:mirakl_order_line) { instance_double Mirakl::OrderLine }
      let(:line_item) { create(:line_item, price: 50, quantity: 2) }

      before do
        allow(reimbursement).to receive(:order).and_return(order)
        allow(reimbursement).to receive(:mirakl_order_line_reimbursement).and_return(mirakl_order_line_reimbursement)
        allow(refund).to receive(:reimbursement).and_return(reimbursement)
        allow(mirakl_order_line_reimbursement).to receive(:order_line).and_return(mirakl_order_line)
        allow(mirakl_order_line).to receive(:line_item).and_return(line_item)
        allow(mirakl_order_line_reimbursement).to receive(:total).and_return(100)
        allow(order).to receive(:currency).and_return('USD')
      end

      context 'when the order has no order discounts' do
        let(:order) { create(:order_with_line_items, user: user, line_items: [line_item]) }

        context 'when entire line item is returned' do
          before do
            allow(mirakl_order_line_reimbursement).to receive(:quantity).and_return(2)
          end

          it 'returns correct quantity and amount' do
            expect(line.lines.first).to include(number: number)
            expect(line.lines.first).to include(quantity: 2)
            expect(line.lines.first).to include(amount: -100.0)
          end
        end

        context 'when partial line item is returned' do
          before do
            allow(mirakl_order_line_reimbursement).to receive(:quantity).and_return(1)
          end

          it 'returns correct quantity and amount' do
            expect(line.lines.first).to include(number: number)
            expect(line.lines.first).to include(quantity: 1)
            expect(line.lines.first).to include(amount: -50.0)
          end
        end
      end

      context 'when the order has order discounts' do
        let(:order) { create(:order, user: user, line_items: [line_item], item_total: 100.0) }
        let(:adjustment) { create(:adjustment, amount: -10, order: order) }

        context 'when entire line item is returned' do
          before do
            adjustment
            allow(mirakl_order_line_reimbursement).to receive(:quantity).and_return(2)
          end

          it 'returns correct quantity and amount' do
            expect(line.lines.first).to include(number: number)
            expect(line.lines.first).to include(quantity: 2)
            expect(line.lines.first).to include(amount: -90.0)
          end
        end

        context 'when partial line item is returned' do
          before do
            adjustment
            allow(mirakl_order_line_reimbursement).to receive(:quantity).and_return(1)
          end

          it 'returns correct quantity and amount' do
            expect(line.lines.first).to include(number: number)
            expect(line.lines.first).to include(quantity: 1)
            expect(line.lines.first).to include(amount: -45.0)
          end
        end
      end
    end

    context 'when the refund does not have a reimbursement' do
      let(:number) { '123-RA' }
      let(:reimbursement) { nil }
      let(:order) { create(:order_with_line_items, user: user) }
      let(:refund) { instance_double Spree::Refund }
      let(:user) { create(:user, exemption_number: 'exempt', vat_id: 'vat id') }

      before do
        allow(refund).to receive(:reimbursement).and_return(reimbursement)
        allow(refund).to receive(:id).and_return('123')
        allow(refund).to receive(:transaction_id).and_return('456')
        allow(refund).to receive(:amount).and_return('10')
      end

      it 'call refund method' do
        expect(line.lines.first).to include(number: number)
      end
    end
  end
end
