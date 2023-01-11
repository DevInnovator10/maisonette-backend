# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ShopCreditsInvoiceWorker, mirakl: true do
  describe 'perform' do
    let(:shop_ids) { [shop_id1, shop_id2] }
    let(:shop_id1) { [2002, 1] }
    let(:shop_id2) { [4004, 2] }
    let(:orders_for_shop1) { class_double Mirakl::Order, update_all: true }
    let(:orders_for_shop2) { class_double Mirakl::Order, update_all: true }

    let(:refunds) do
      class_double Mirakl::OrderLineReimbursement,
                   created_last_month_and_order_received: created_last_month_and_order_received
    end
    let(:created_last_month_and_order_received) do
      class_double Mirakl::OrderLineReimbursement,
                   has_cost_price_total: has_cost_price_total
    end
    let(:has_cost_price_total) { class_double Mirakl::OrderLineReimbursement, shop_ids: reimbursement_shop_ids }
    let(:reimbursement_shop_ids) { [] }
    let(:reimb_cost_price_for_shop_id1) { [] }
    let(:reimb_cost_price_for_shop_id2) { [] }

    before do
      allow(Mirakl::Order).to receive_messages(invoicing_date_last_month_shop_ids: shop_ids)
      allow(Mirakl::Order).to(
        receive(:invoicing_date_last_month_for_shop).with(shop_id1[0]).and_return(orders_for_shop1)
      )
      allow(Mirakl::Order).to(
        receive(:invoicing_date_last_month_for_shop).with(shop_id2[0]).and_return(orders_for_shop2)
      )
      allow(Mirakl::Invoice).to receive(:create)

      allow(has_cost_price_total).to receive(:for_shop_id).with(shop_id1[0]).and_return(reimb_cost_price_for_shop_id1)
      allow(has_cost_price_total).to receive(:for_shop_id).with(shop_id2[0]).and_return(reimb_cost_price_for_shop_id2)

      allow(Mirakl::OrderLineReimbursement).to receive_messages(refund: refunds)

      allow(Mirakl::Invoices::CreateCreditsInteractor).to receive(:call)
    end

    context 'when shop_ids are not passed in' do
      let(:shop_credit_invoice_worker) { described_class.new }

      before do
        allow(shop_credit_invoice_worker).to receive(:delete_unissued_invoices)

        shop_credit_invoice_worker.perform
      end

      it 'does call #delete_unissued_invoices' do
        expect(shop_credit_invoice_worker).to have_received(:delete_unissued_invoices)
      end

      it 'calls Mirakl::Invoices::CreateCreditsInteractor for orders received last month, grouped by shop' do
        expect(Mirakl::Invoices::CreateCreditsInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop1,
                                    cost_price_order_line_reimbs: [],
                                    shop_id: shop_id1[1],
                                    mirakl_shop_id: shop_id1[0])
        )
        expect(Mirakl::Invoices::CreateCreditsInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop2,
                                    cost_price_order_line_reimbs: [],
                                    shop_id: shop_id2[1],
                                    mirakl_shop_id: shop_id2[0])
        )
      end
    end

    context 'when shop_ids are passed in' do
      let(:shop_credit_invoice_worker) { described_class.new }
      let(:shop_id1) { [2025, 5] }

      before do
        allow(shop_credit_invoice_worker).to receive(:delete_unissued_invoices)

        shop_credit_invoice_worker.perform(shop_ids: [shop_id1])
      end

      it 'does not call #delete_unissued_invoices' do
        expect(shop_credit_invoice_worker).not_to have_received(:delete_unissued_invoices)
      end

      it 'callsMirakl::Invoices::CreateCreditsInteractor for passed in shop' do
        expect(Mirakl::Invoices::CreateCreditsInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop1,
                                    cost_price_order_line_reimbs: [],
                                    shop_id: shop_id1[1],
                                    mirakl_shop_id: shop_id1[0])
        )
      end
    end

    context 'when there are order line reimbursements with mark down prices for the previous month' do
      let(:reimbursement_shop_ids) { [shop_id2, shop_id3] }
      let(:shop_id3) { [6006, 3] }
      let(:reimb_for_shop_id1) { [] }
      let(:reimb_cost_price_for_shop_id2) { order_line_reimbursements_for_shop2 }
      let(:reimb_cost_price_for_shop_id3) { order_line_reimbursements_for_shop3 }

      let(:orders_for_shop3) { class_double Mirakl::Order, update_all: true }

      let(:order_line_reimbursements_for_shop2) { [mirakl_order_line_reimb1, mirakl_order_line_reimb2] }
      let(:order_line_reimbursements_for_shop3) { [mirakl_order_line_reimb3, mirakl_order_line_reimb4] }

      let(:mirakl_order_line_reimb1) { instance_double Mirakl::OrderLineReimbursement }
      let(:mirakl_order_line_reimb2) { instance_double Mirakl::OrderLineReimbursement }
      let(:mirakl_order_line_reimb3) { instance_double Mirakl::OrderLineReimbursement }
      let(:mirakl_order_line_reimb4) { instance_double Mirakl::OrderLineReimbursement }

      before do
        allow(Mirakl::Order).to(
          receive(:invoicing_date_last_month_for_shop).with(shop_id3[0]).and_return(orders_for_shop3)
        )
        allow(has_cost_price_total).to(
          receive(:for_shop_id).with(shop_id3[0]).and_return(reimb_cost_price_for_shop_id3)
        )

        allow(Mirakl::Invoices::CreateCreditsInteractor).to receive(:call)

        described_class.new.perform
      end

      it 'calls Mirakl::Invoices::CreateCreditsInteractor with the order line reimbursements as well' do
        expect(Mirakl::Invoices::CreateCreditsInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop1,
                                    cost_price_order_line_reimbs: [],
                                    shop_id: shop_id1[1],
                                    mirakl_shop_id: shop_id1[0])
        )
        expect(Mirakl::Invoices::CreateCreditsInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop2,
                                    cost_price_order_line_reimbs: order_line_reimbursements_for_shop2,
                                    shop_id: shop_id2[1],
                                    mirakl_shop_id: shop_id2[0])
        )
        expect(Mirakl::Invoices::CreateCreditsInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop3,
                                    cost_price_order_line_reimbs: order_line_reimbursements_for_shop3,
                                    shop_id: shop_id3[1],
                                    mirakl_shop_id: shop_id3[0])
        )
      end
    end
  end
end
