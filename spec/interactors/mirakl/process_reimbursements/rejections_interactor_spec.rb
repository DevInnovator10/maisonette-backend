# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ProcessReimbursements::RejectionsInteractor, mirakl: true do
    describe '#call' do
    let(:interactor) do
      described_class.new(order_line_payload: order_line_payload,
                          mirakl_order_line: mirakl_order_line,
                          mirakl_order: mirakl_order)
    end
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: 'R123-A' }

    let(:context) { interactor.context }
    let(:mirakl_order_line) { instance_double Mirakl::OrderLine, mirakl_order_line_id: '123-A' }
    let(:order_line_payload) do
      {
        'order_line_state' => order_line_state,
        'price' => 10.5,
        'quantity' => 2,
        'taxes' => taxes,
        'shipping_price' => 9.95,
        'shipping_taxes' => shipping_taxes,
      }
    end
    let(:order_line_state) {}
    let(:taxes) { ['tax' => 1.1] }
    let(:shipping_taxes) { ['tax' => 1.3] }
    let(:order_line_reimbursement) { instance_double Mirakl::OrderLineReimbursement, calculate_total: true }
    let(:inventory_units) { class_double Spree::InventoryUnit }
    let(:rejected_by_vendor_reason) { MIRAKL_DATA[:order][:refund_reason][:rejected_by_vendor] }
    let(:refund_reason) { instance_double Spree::RefundReason, name: rejected_by_vendor_reason }
    let(:previously_created_reimbursement) {}

    context 'when it is successful' do
      before do
        previously_created_reimbursement
        allow(previously_created_reimbursement).to receive(:calculate_total)

        allow(Mirakl::OrderLineReimbursement).to receive_messages(new: order_line_reimbursement)
        allow(mirakl_order_line).to receive(:total_tax_amount).with(taxes).and_return(1.1)
        allow(mirakl_order_line).to receive(:total_tax_amount).with(shipping_taxes).and_return(1.3)
        allow(interactor).to receive_messages(inventory_units: inventory_units)
        allow(Spree::RefundReason).to receive_messages(find_or_create_by!: refund_reason)

        interactor.call
      end

      context 'when the order line is refused' do
        let(:order_line_state) { 'REFUSED' }

        it 'add a Mirakl::OrderLineReimbursement to the context' do
          expect(context.reimbursements).to eq [order_line_reimbursement]
        end

        context 'when a matching Mirakl::OrderLineReimbursement does not exist' do
          let(:previously_created_reimbursement) {}

          it 'initializes a Mirakl::OrderLineReimbursement with order line payload' do
            expect(Mirakl::OrderLineReimbursement).to have_received(:new).with(
              mirakl_reimbursement_id: mirakl_order_line.mirakl_order_line_id,
              quantity: 2,
              refund_reason: refund_reason,
              order_line: mirakl_order_line,
              mirakl_type: 'rejection',
              amount: 10.5,
              tax: 1.1,
              shipping_amount: 9.95,
              shipping_tax: 1.3,
              inventory_units: inventory_units
            )

            expect(order_line_reimbursement).to have_received(:calculate_total)
            expect(context.reimbursements).to eq [order_line_reimbursement]
          end
        end

        context 'when a matching Mirakl::OrderLineReimbursement does exist' do
          let(:previously_created_reimbursement) do
            create :mirakl_order_line_reimbursement,
                   :rejection,
                   mirakl_reimbursement_id: mirakl_order_line.mirakl_order_line_id
          end

          it 'uses the existing Mirakl::OrderLineReimbursement' do
            expect(Mirakl::OrderLineReimbursement).not_to have_received(:new)
            expect(previously_created_reimbursement).not_to have_received(:calculate_total)

            expect(context.reimbursements).to eq [previously_created_reimbursement]
          end
        end

        it 'finds or creates refund reasons for "rejected by vendor"' do
          expect(Spree::RefundReason).to have_received(:find_or_create_by!).with(name: rejected_by_vendor_reason)
        end
      end

      context 'when the order line is not refused' do
        let(:order_line_state) { 'SHIPPED' }

        it 'does not add Mirakl::OrderLineReimbursement to the context' do
          expect(context.reimbursements).to eq nil
        end
      end
    end

    context 'when it errors' do
      let(:exception) { StandardError.new('something went wrong') }
      let(:order_line_state) { 'REFUSED' }

      before do
        allow(interactor).to receive(:rescue_and_capture)
        allow(interactor).to receive(:find_or_create_order_line_reimb).and_raise(exception)

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
end
