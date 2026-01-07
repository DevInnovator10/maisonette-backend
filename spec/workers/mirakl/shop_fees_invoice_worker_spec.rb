# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ShopFeesInvoiceWorker do
  describe 'perform' do
    let(:shop_ids) { [shop_id1, shop_id2] }
    let(:shop_id1) { [2002, 1] }
    let(:shop_id2) { [4004, 2] }
    let(:orders_for_shop1) { class_double Mirakl::Order, update_all: true }
    let(:orders_for_shop2) { class_double Mirakl::Order, update_all: true }

    let(:return_fees) do
      class_double Mirakl::OrderLineReimbursement,
                   refund: return_fees_refund
    end
    let(:return_fees_refund) do
      class_double Mirakl::OrderLineReimbursement,
                   created_last_month_and_order_received: return_fee_last_month
    end
    let(:return_fee_last_month) { class_double Mirakl::OrderLineReimbursement, shop_ids: return_fee_shop_ids }
    let(:return_fee_shop_ids) { [] }
    let(:refunds) do
      class_double Mirakl::OrderLineReimbursement,
                   created_last_month_and_order_received: created_last_month_and_order_received
    end
    let(:created_last_month_and_order_received) do
      class_double Mirakl::OrderLineReimbursement,
                   has_marked_down_prices: has_marked_down_prices
    end
    let(:has_marked_down_prices) { class_double Mirakl::OrderLineReimbursement, shop_ids: reimbursement_shop_ids }
    let(:reimbursement_shop_ids) { [] }
    let(:reimb_mark_down_for_shop_id1) { [] }
    let(:reimb_mark_down_for_shop_id2) { [] }
    let(:reimb_return_fee_for_shop_id1) { [] }
    let(:reimb_return_fee_for_shop_id2) { [] }

    before do
      allow(Mirakl::Order).to receive_messages(invoicing_date_last_month_shop_ids: shop_ids)
      allow(Mirakl::Order).to(
        receive(:invoicing_date_last_month_for_shop).with(shop_id1[0]).and_return(orders_for_shop1)
      )
      allow(Mirakl::Order).to(
        receive(:invoicing_date_last_month_for_shop).with(shop_id2[0]).and_return(orders_for_shop2)
      )
      allow(Mirakl::Invoice).to receive(:create)

      allow(has_marked_down_prices).to receive(:for_shop_id).with(shop_id1[0]).and_return(reimb_mark_down_for_shop_id1)
      allow(has_marked_down_prices).to receive(:for_shop_id).with(shop_id2[0]).and_return(reimb_mark_down_for_shop_id2)
      allow(return_fee_last_month).to receive(:for_shop_id).with(shop_id1[0]).and_return(reimb_return_fee_for_shop_id1)
      allow(return_fee_last_month).to receive(:for_shop_id).with(shop_id2[0]).and_return(reimb_return_fee_for_shop_id2)

      allow(Mirakl::OrderLineReimbursement).to receive_messages(refund: refunds, has_return_fees: return_fees)
      allow(Mirakl::Invoices::CreateFeesInteractor).to receive(:call)
    end

    context 'when there are no order line reimbursements' do
      before { described_class.new.perform }

      it 'calls Mirakl::Invoices::CreateFeesInteractor for orders received last month, grouped by shop' do
        expect(Mirakl::Invoices::CreateFeesInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop1,
                                    mark_down_order_line_reimbs: [],
                                    return_fees_line_reimbs: [],
                                    shop_id: shop_id1[1],
                                    mirakl_shop_id: shop_id1[0])
        )
        expect(Mirakl::Invoices::CreateFeesInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop2,
                                    mark_down_order_line_reimbs: [],
                                    return_fees_line_reimbs: [],
                                    shop_id: shop_id2[1],
                                    mirakl_shop_id: shop_id2[0])
        )
      end
    end

    context 'when there are order line reimbursements with mark down prices for the previous month' do
      let(:reimbursement_shop_ids) { [shop_id2, shop_id3] }
      let(:shop_id3) { [6006, 3] }
      let(:reimb_mark_down_for_shop_id2) { order_line_reimbursements_for_shop2 }
      let(:reimb_mark_down_for_shop_id3) { order_line_reimbursements_for_shop3 }
      let(:reimb_return_fee_for_shop_id3) { [] }

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
        allow(has_marked_down_prices).to(
          receive(:for_shop_id).with(shop_id3[0]).and_return(reimb_mark_down_for_shop_id3)
        )
        allow(return_fee_last_month).to(
          receive(:for_shop_id).with(shop_id3[0]).and_return(reimb_return_fee_for_shop_id3)
        )

        allow(Mirakl::Invoices::CreateFeesInteractor).to receive(:call)

        described_class.new.perform
      end

      it 'calls Mirakl::Invoices::CreateFeesInteractor with the order line reimbursements as well' do
        expect(Mirakl::Invoices::CreateFeesInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop1,
                                    mark_down_order_line_reimbs: [],
                                    return_fees_line_reimbs: [],
                                    shop_id: shop_id1[1], mirakl_shop_id: shop_id1[0])
        )
        expect(Mirakl::Invoices::CreateFeesInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop2,
                                    mark_down_order_line_reimbs: order_line_reimbursements_for_shop2,
                                    return_fees_line_reimbs: [],
                                    shop_id: shop_id2[1], mirakl_shop_id: shop_id2[0])
        )
        expect(Mirakl::Invoices::CreateFeesInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop3,
                                    mark_down_order_line_reimbs: order_line_reimbursements_for_shop3,
                                    return_fees_line_reimbs: [],
                                    shop_id: shop_id3[1], mirakl_shop_id: shop_id3[0])
        )
      end
    end

    context 'when there are order line reimbursements with return_fee for the previous month' do
      let(:return_fee_shop_ids) { [shop_id2, shop_id3] }
      let(:shop_id3) { [6006, 3] }
      let(:reimb_return_fee_for_shop_id2) { order_line_reimbursements_with_fee_for_shop2 }
      let(:reimb_return_fee_for_shop_id3) { order_line_reimbursements_with_fee_for_shop3 }
      let(:reimb_mark_down_for_shop_id3) { [] }

      let(:orders_for_shop3) { class_double Mirakl::Order, update_all: true }

      let(:order_line_reimbursements_with_fee_for_shop2) { [mirakl_order_line_reimb1, mirakl_order_line_reimb2] }
      let(:order_line_reimbursements_with_fee_for_shop3) { [mirakl_order_line_reimb3, mirakl_order_line_reimb4] }

      let(:mirakl_order_line_reimb1) { instance_double Mirakl::OrderLineReimbursement }
      let(:mirakl_order_line_reimb2) { instance_double Mirakl::OrderLineReimbursement }
      let(:mirakl_order_line_reimb3) { instance_double Mirakl::OrderLineReimbursement }
      let(:mirakl_order_line_reimb4) { instance_double Mirakl::OrderLineReimbursement }

      before do
        allow(Mirakl::Order).to(
          receive(:invoicing_date_last_month_for_shop).with(shop_id3[0]).and_return(orders_for_shop3)
        )
        allow(has_marked_down_prices).to(
          receive(:for_shop_id).with(shop_id3[0]).and_return(reimb_mark_down_for_shop_id3)
        )
        allow(return_fee_last_month).to(
          receive(:for_shop_id).with(shop_id3[0]).and_return(reimb_return_fee_for_shop_id3)
        )

        allow(Mirakl::Invoices::CreateFeesInteractor).to receive(:call)

        described_class.new.perform
      end

      it 'calls Mirakl::Invoices::CreateFeesInteractor with the order line reimbursements as well' do
        expect(Mirakl::Invoices::CreateFeesInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop1,
                                    mark_down_order_line_reimbs: [],
                                    return_fees_line_reimbs: [],
                                    shop_id: shop_id1[1], mirakl_shop_id: shop_id1[0])
        )
        expect(Mirakl::Invoices::CreateFeesInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop2,
                                    mark_down_order_line_reimbs: [],
                                    return_fees_line_reimbs: order_line_reimbursements_with_fee_for_shop2,
                                    shop_id: shop_id2[1], mirakl_shop_id: shop_id2[0])
        )
        expect(Mirakl::Invoices::CreateFeesInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop3,
                                    mark_down_order_line_reimbs: [],
                                    return_fees_line_reimbs: order_line_reimbursements_with_fee_for_shop3,
                                    shop_id: shop_id3[1], mirakl_shop_id: shop_id3[0])
        )
      end
    end

    context 'when shop_ids are not passed in' do
      let(:shop_fees_invoice_worker) { described_class.new }

      before do
        allow(shop_fees_invoice_worker).to receive(:delete_unissued_invoices)

        shop_fees_invoice_worker.perform
      end

      it 'does call #delete_unissued_invoices' do
        expect(shop_fees_invoice_worker).to have_received(:delete_unissued_invoices)
      end
    end

    context 'when shop_ids are passed in' do
      let(:shop_fees_invoice_worker) { described_class.new }
      let(:shop_id1) { [2025, 5] }

      before do
        allow(shop_fees_invoice_worker).to receive(:delete_unissued_invoices)

        shop_fees_invoice_worker.perform(shop_ids: [shop_id1])
      end

      it 'does not call #delete_unissued_invoices' do
        expect(shop_fees_invoice_worker).not_to have_received(:delete_unissued_invoices)
      end

      it 'calls Mirakl::Invoices::CreateFeesInteractor.create_fees_invoice, using the passed in shop id' do
        expect(Mirakl::Invoices::CreateFeesInteractor).to(
          have_received(:call).with(mirakl_orders: orders_for_shop1,
                                    mark_down_order_line_reimbs: [],
                                    return_fees_line_reimbs: [],
                                    shop_id: shop_id1[1],
                                    mirakl_shop_id: shop_id1[0])
        )
      end
    end
  end
end
