# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Invoices::CreateCreditsInteractor, mirakl: true do
  describe 'hooks' do
    let(:interactor) { described_class.new }

    it 'has before hooks' do
      expect(described_class.before_hooks).to eq [:use_operator_key]
    end
  end

  describe '#invoice_type' do
    it 'returns :credit' do
      expect(described_class.new.send(:invoice_type)).to eq 'CREDIT'
    end
  end

  describe '#lines' do
    subject(:lines) { create_credits_invoice.send :lines }

    let(:create_credits_invoice) do
      described_class.new(mirakl_orders: mirakl_orders,
                          cost_price_order_line_reimbs: cost_price_order_line_reimbs,
                          shop_id: shop_id)
    end
    let(:mirakl_orders) { [mirakl_order1, mirakl_order2] }
    let(:cost_price_order_line_reimbs) do
      [mirakl_order_line_reimb_3, mirakl_order_line_reimb_4, mirakl_order_line_reimb_5, mirakl_order_line_reimb_6]
    end
    let(:shop_id) { 2002 }
    let(:mirakl_order1) { build_stubbed :mirakl_order, mirakl_payload: mirakl_payload1 }
    let(:mirakl_order2) { build_stubbed :mirakl_order, mirakl_payload: mirakl_payload2 }
    let(:mirakl_order_line_reimb_3) do
      instance_double Mirakl::OrderLineReimbursement, order_line: order_line_1, quantity: 3
    end
    let(:mirakl_order_line_reimb_4) do
      instance_double Mirakl::OrderLineReimbursement, order_line: order_line_1, quantity: 1
    end
    let(:mirakl_order_line_reimb_5) do
      # partial reimbursement, should be skipped
      instance_double Mirakl::OrderLineReimbursement, order_line: order_line_1, quantity: nil
    end
    let(:mirakl_order_line_reimb_6) do
      # partial reimbursement, should be skipped
      instance_double Mirakl::OrderLineReimbursement, order_line: order_line_1, quantity: 0
    end
    let(:order_line_1) do
      instance_double Mirakl::OrderLine,
                      vendor_mark_down_credit_amount: 5.0,
                      order: mirakl_order1,
                      cost_price_fee_amount: 10.0
    end

    let(:mirakl_payload1) do
      { 'order_additional_fields' => [{ 'code' => MIRAKL_DATA[:order][:additional_fields][:dropship_surcharge],
                                        'value' => mirakl_order1_dropship_surcharge },
                                      { 'code' => MIRAKL_DATA[:order][:additional_fields][:gift_wrap_vendor_fee],
                                        'value' => mirakl_order1_gift_wrap_vendor_fee },
                                      { 'code' => MIRAKL_DATA[:order][:additional_fields][:mark_down_credit],
                                        'value' => mirakl_order1_mark_down_credit },
                                      { 'code' => MIRAKL_DATA[:order][:additional_fields][:incidental_credit],
                                        'value' => mirakl_order1_incidental_credit },
                                      { 'code' => MIRAKL_DATA[:order][:additional_fields][:incidental_credit_reason],
                                        'value' => mirakl_order1_incidental_credit_reason }] }
    end
    let(:mirakl_order1_dropship_surcharge) { 5.56 }
    let(:mirakl_order1_gift_wrap_vendor_fee) { 10.2 }
    let(:mirakl_order1_mark_down_credit) { 15.05 }
    let(:mirakl_order_line_reimb_3_cost_price_fee) { 30.0 }
    let(:mirakl_order_line_reimb_4_cost_price_fee) { 10.0 }
    let(:mirakl_order1_incidental_credit) { 23.3 }
    let(:mirakl_order1_incidental_credit_reason) { 'Some Credit Reason' }
    let(:mirakl_order2_incidental_credit) { 33.33 }
    let(:mirakl_payload2) do
      { 'order_additional_fields' => [{ 'code' => MIRAKL_DATA[:order][:additional_fields][:dropship_surcharge],
                                        'value' => mirakl_order2_dropship_surcharge },
                                      { 'code' => MIRAKL_DATA[:order][:additional_fields][:incidental_credit],
                                        'value' => mirakl_order2_incidental_credit }] }
    end
    let(:mirakl_order2_dropship_surcharge) { 3.0 }
    let(:credits_invoice_payload) do
      { manual_accounting_documents: [{ issued: false,
                                        lines: lines,
                                        shop_id: shop_id,
                                        type: 'CREDIT' }] }.to_json
    end

    let(:mirakl_order1_dropship_surcharge_line) do
      { mirakl_order: mirakl_order1.logistic_order_id,
        invoice_line:
          { amount: mirakl_order1_dropship_surcharge,
            description: "#{mirakl_order1.logistic_order_id}: #{MIRAKL_DATA[:invoice][:lines][:dropship_surcharge]}",
            quantity: 1,
            tax_codes: ['TAXDEFAULT'] } }
    end

    let(:mirakl_order1_gift_wrap_vendor_fee_line) do
      { mirakl_order: mirakl_order1.logistic_order_id,
        invoice_line:
          { amount: mirakl_order1_gift_wrap_vendor_fee,
            description: "#{mirakl_order1.logistic_order_id}: #{MIRAKL_DATA[:invoice][:lines][:gift_wrap_vendor_fee]}",
            quantity: 1,
            tax_codes: ['TAXDEFAULT'] } }
    end

    let(:mirakl_order1_mark_down_credit_line) do
      { mirakl_order: mirakl_order1.logistic_order_id,
        invoice_line:
          { amount: mirakl_order1_mark_down_credit,
            description: "#{mirakl_order1.logistic_order_id}: #{MIRAKL_DATA[:invoice][:lines][:mark_down_credit]}",
            quantity: 1,
            tax_codes: ['TAXDEFAULT'] } }
    end

    let(:mirakl_order_line_reimb_3_cost_price_fee_line) do
      { mirakl_order: mirakl_order1.logistic_order_id,
        invoice_line:
          { amount: mirakl_order_line_reimb_3_cost_price_fee,
            description: "#{mirakl_order1.logistic_order_id}: #{MIRAKL_DATA[:invoice][:lines][:cost_price_refund]}",
            quantity: 1,
            tax_codes: ['TAXDEFAULT'] } }
    end

    let(:mirakl_order_line_reimb_4_cost_price_fee_line) do
      { mirakl_order: mirakl_order1.logistic_order_id,
        invoice_line:
          { amount: mirakl_order_line_reimb_4_cost_price_fee,
            description: "#{mirakl_order1.logistic_order_id}: #{MIRAKL_DATA[:invoice][:lines][:cost_price_refund]}",
            quantity: 1,
            tax_codes: ['TAXDEFAULT'] } }
    end

    let(:mirakl_order2_dropship_surcharge_line) do
      { mirakl_order: mirakl_order2.logistic_order_id,
        invoice_line:
          { amount: mirakl_order2_dropship_surcharge,
            description: "#{mirakl_order2.logistic_order_id}: #{MIRAKL_DATA[:invoice][:lines][:dropship_surcharge]}",
            quantity: 1,
            tax_codes: ['TAXDEFAULT'] } }
    end

    let(:mirakl_order1_incidental_credit_line) do
      { mirakl_order: mirakl_order1.logistic_order_id,
        invoice_line:
          { amount: mirakl_order1_incidental_credit,
            description: "#{mirakl_order1.logistic_order_id}: #{mirakl_order1_incidental_credit_reason}",
            quantity: 1,
            tax_codes: ['TAXDEFAULT'] } }
    end

    let(:mirakl_order2_incidental_credit_line) do
      { mirakl_order: mirakl_order2.logistic_order_id,
        invoice_line:
          { amount: mirakl_order2_incidental_credit,
            description: "#{mirakl_order2.logistic_order_id}: #{MIRAKL_DATA[:invoice][:lines][:incidental_credit]}",
            quantity: 1,
            tax_codes: ['TAXDEFAULT'] } }
    end

    it 'returns invoice lines' do
      expect(lines).to match_array [mirakl_order1_incidental_credit_line,
                                    mirakl_order2_incidental_credit_line,
                                    mirakl_order1_dropship_surcharge_line,
                                    mirakl_order2_dropship_surcharge_line,
                                    mirakl_order1_mark_down_credit_line,
                                    mirakl_order_line_reimb_3_cost_price_fee_line,
                                    mirakl_order_line_reimb_4_cost_price_fee_line,
                                    mirakl_order1_gift_wrap_vendor_fee_line]
    end
  end
end
