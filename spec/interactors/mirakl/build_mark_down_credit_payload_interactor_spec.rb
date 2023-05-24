# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::BuildMarkDownCreditPayloadInteractor, mirakl: true do
  describe 'hooks' do
    let(:interactor) { described_class.new }

    it 'has before hooks' do
      expect(described_class.before_hooks).to eq [:adjust_for_reimbursements]
    end
  end

  describe '#call' do
    let(:interactor) { described_class.new(mirakl_order: mirakl_order) }
    let(:interactor_call) { interactor.call }
    let(:mirakl_order) do
      instance_double Mirakl::Order,
                      order_lines: order_lines,
                      logistic_order_id: 'R123-A',
                      invoiced?: invoiced
    end
    let(:order_lines) { class_double Mirakl::OrderLine, has_marked_down_prices: has_marked_down_prices }
    let(:order_line1) { instance_double Mirakl::OrderLine, vendor_mark_down_credit_total: 7.08 }
    let(:order_line2) { instance_double Mirakl::OrderLine, vendor_mark_down_credit_total: 7.08 }
    let(:order_mark_down_credit_total) { 14.6 }
    let(:has_marked_down_prices) { class_double Mirakl::OrderLine, any?: any_marked_down_prices? }
    let(:any_marked_down_prices?) { true }
    let(:invoiced) { false }
    let(:payload) do
      { code: MIRAKL_DATA[:order][:additional_fields][:mark_down_credit],
        value: order_mark_down_credit_total }
    end

    context 'when it is successful' do
      before do
        allow(interactor).to receive(:calculate_mark_down_credits)
        allow(order_lines).to receive(:sum).and_return(order_mark_down_credit_total)

        interactor_call
      end

      it 'calls calculate_mark_down_credits' do
        expect(interactor).to have_received(:calculate_mark_down_credits)
      end

      context 'when there are order lines with marked down prices' do
        let(:any_marked_down_prices?) { true }

        it 'add the payload to mirakl_order_additional_fields_payload' do
          expect(interactor.context.mirakl_order_additional_fields_payload).to eq [payload]
        end

        it 'sums up vendor_mark_down_credit_total on Mirakl::OrderLines' do
          expect(order_lines).to have_received(:sum).with(:vendor_mark_down_credit_total)
        end
      end

      context 'when there are no order lines with marked down prices' do
        let(:any_marked_down_prices?) { false }

        it 'does not add the payload to mirakl_order_additional_fields_payload' do
          expect(interactor.context.mirakl_order_additional_fields_payload).to eq nil
        end
      end

      context 'with a mark-down-credits with extra decimals' do
        let(:order_mark_down_credit_total) { 48.599999999999994 }

        it 'rounds the mark down credit value' do
          expect(interactor_call.first[:value]).to eq 48.6
        end
      end
    end

    context 'when it errors' do
      let(:exception) { StandardError.new('something went wrong') }

      before do
        allow(interactor).to receive(:rescue_and_capture)
        allow(interactor).to receive(:calculate_mark_down_credits).and_raise(exception)

        interactor.call
      end

      it 'rescues and captures the exception' do
        expect(interactor).to(
          have_received(:rescue_and_capture).with(exception,
                                                  extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        )
      end
    end
  end

  describe '#adjust_for_reimbursements' do
    let(:interactor) { described_class.new(mirakl_order: mirakl_order) }
    let(:mirakl_order) { instance_double Mirakl::Order, order_lines: order_lines }
    let(:order_lines) { class_double Mirakl::OrderLine, has_marked_down_prices: has_marked_down_prices }
    let(:has_marked_down_prices) do
      class_double Mirakl::OrderLine, with_order_line_reimbursements: order_lines_with_reimbursements
    end
    let(:order_line) do
      instance_double Mirakl::OrderLine,
                      update: true,
                      vendor_mark_down_credit_amount: 5.05,
                      quantity: 5,
                      order_line_reimbursements: order_line_reimbursements
    end
    let(:order_line_reimbursements) do
      class_double Mirakl::OrderLineReimbursement, refunds_or_rejections: reimbursement_refunds_or_rejections
    end
    let(:reimbursement_refunds_or_rejections) do
      class_double Mirakl::OrderLineReimbursement, sum: reimb_refund_qty + reimb_reject_qty
    end
    let(:reimb_refund_qty) { 0 }
    let(:reimb_reject_qty) { 0 }

    before do
      allow(interactor).to receive(:call)

      interactor.run
    end

    context 'when there are no reimbursements' do
      let(:order_lines_with_reimbursements) { [] }

      it 'does not update the vendor_mark_down_credit_total' do
        expect(order_line).not_to have_received(:update)
      end
    end

    context 'when there are reimbursements' do
      let(:order_lines_with_reimbursements) { [order_line] }

      it 'updates the vendor_mark_down_credit_total on the order line' do
        expect(order_line).to have_received(:update).with(vendor_mark_down_credit_total: 25.25)
      end

      it 'sums up the quantity of refund reimbursements' do
        expect(reimbursement_refunds_or_rejections).to have_received(:sum).with(:quantity)
      end

      context 'when there are refund reimbursements' do
        let(:reimb_refund_qty) { 2 }

        it 'updates the vendor_mark_down_credit_total on the order line minus the refund mark down amount' do
          expect(order_line).to have_received(:update).with(vendor_mark_down_credit_total: 15.15)
        end
      end

      context 'when there are rejection reimbursements' do
        let(:reimb_reject_qty) { 2 }

        it 'updates the mark_down_credit_total on the order line minus the refund mark down amount' do
          expect(order_line).to have_received(:update).with(vendor_mark_down_credit_total: 15.15)
        end
      end

      context 'when there are refund and rejection reimbursements' do
        let(:reimb_refund_qty) { 2 }
        let(:reimb_reject_qty) { 2 }

        it 'updates the vendor_mark_down_credit_total on the order line minus the refund mark down amount' do
          expect(order_line).to have_received(:update).with(vendor_mark_down_credit_total: 5.050000000000001)
        end
      end
    end
  end

  describe '#calculate_mark_down_credits' do
    subject(:calculate_mark_down_credits) { interactor.send :calculate_mark_down_credits }

    let(:interactor) { described_class.new(mirakl_order: mirakl_order) }

    let(:mirakl_order) do
      instance_double Mirakl::Order,
                      order_lines: order_lines,
                      shipment: shipment
    end

    let(:shipment) { instance_double Spree::Shipment, stock_location: stock_location }
    let(:stock_location) { instance_double Spree::StockLocation, mirakl_shop: mirakl_shop }
    let(:mirakl_shop) { instance_double Mirakl::Shop, cost_price?: mirakl_shop_is_cost_price? }
    let(:mirakl_shop_is_cost_price?) {}

    let(:order_lines) { [order_line1, order_line2] }
    let(:order_line1) do
      instance_double Mirakl::OrderLine,

                      update: true,
                      vendor_mark_down_credit_amount: vendor_mark_down_credit_amount1,
                      line_item: line_item1,
                      commission_fee: commission_fee1,
                      quantity: 1,
                      price_unit: price_unit1
    end
    let(:order_line2) do
      instance_double Mirakl::OrderLine,
                      update: true,
                      vendor_mark_down_credit_amount: nil,
                      line_item: line_item2,
                      commission_fee: commission_fee2,
                      quantity: 2,
                      price_unit: price_unit2
    end
    let(:vendor_mark_down_credit_amount1) { nil }
    let(:commission_fee1) {}
    let(:commission_fee2) {}
    let(:price_unit1) {}
    let(:price_unit2) {}

    let(:line_item1) do
      instance_double Spree::LineItem,
                      discountable: discountable,
                      mark_down_our_liability: mark_down_our_liability1,
                      quantity: 1
    end
    let(:line_item2) do
      instance_double Spree::LineItem,
                      discountable: discountable,
                      mark_down_our_liability: mark_down_our_liability2,
                      quantity: 2
    end
    let(:mark_down_our_liability1) { 20.0 }
    let(:mark_down_our_liability2) { 15.0 }

    let(:discountable) { instance_double Maisonette::SaleSkuConfiguration }

    before do
      calculate_mark_down_credits
    end

    context 'when the mirakl shop is cost price based' do
      let(:mirakl_shop_is_cost_price?) { true }

      it 'uses the maisonette liability for the mark down credit amount' do
        expect(order_line1).to have_received(:update).with(vendor_mark_down_credit_amount: 20,
                                                           vendor_mark_down_credit_total: 20)
        expect(order_line2).to have_received(:update).with(vendor_mark_down_credit_amount: 15,
                                                           vendor_mark_down_credit_total: 30)
      end
    end

    context 'when the mirakl shop is commission based' do
      let(:mirakl_shop_is_cost_price?) { false }
      let(:commission_fee1) { 22.5 }
      let(:commission_fee2) { 40.0 }
      let(:price_unit1) { 80.0 }
      let(:price_unit2) { 60.0 }
      # 1 - (commission fee / quantity) / unit price
      # (1 - ((22.5 / 1) / 80.0)).round(2)
      let(:vendor_commission1) { 0.72 }
      # (1 - ((40.0 / 2) / 60.0)).round(2)
      let(:vendor_commission2) { 0.67 }
      # mark down our liability * vendor commission
      # (20.0 * 0.72).round(2)
      let(:order_line1_mark_down_credit_vendor_commission) { 14.4 }
      # (15.0 * 0.67).round(2)
      let(:order_line2_mark_down_credit_vendor_commission) { 10.05 }

      it 'uses the maisonette liability and vendor commission for the mark down credit amount' do
        expect(order_line1).to(
          have_received(:update).with(vendor_mark_down_credit_amount: order_line1_mark_down_credit_vendor_commission,
                                      vendor_mark_down_credit_total: order_line1_mark_down_credit_vendor_commission)
        )
        expect(order_line2).to(
          have_received(:update).with(vendor_mark_down_credit_amount: order_line2_mark_down_credit_vendor_commission,
                                      vendor_mark_down_credit_total: order_line2_mark_down_credit_vendor_commission * 2)
        )
      end
    end

    context 'when maisonette are not liable' do
      let(:mark_down_our_liability1) { 0.0 }

      let(:mark_down_our_liability2) { 15.0 }
      let(:mirakl_shop_is_cost_price?) { true }

      it 'does calculate mark down credit' do
        expect(order_line1).not_to have_received(:update)

        expect(order_line2).to have_received(:update).with(vendor_mark_down_credit_amount: 15,
                                                           vendor_mark_down_credit_total: 30)
      end
    end

    context 'when there is no discountable' do
      let(:discountable) {}

      it 'does calculate mark down credit' do
        expect(order_line1).not_to have_received(:update)
        expect(order_line2).not_to have_received(:update)
      end
    end
  end
end
