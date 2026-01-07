# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::SendSalesOrderInteractor do
  subject(:interactor) { described_class.call(interactor_contexts) }

  let(:interactor_contexts) { { sales_order: sales_order } }

  describe '#call' do
    context 'when successful' do
      let(:sales_order) { build_stubbed(:sales_order, last_request_payload: current_payload) }
      let(:current_payload) { { 'name' => 'payload' } }

      before do
        allow(OrderManagement::ClientInterface).to receive(
          :post_composite_for
        ).with(current_payload, class_name: 'OrderManagement::SalesOrder').and_return(
          OpenStruct.new(order_management_ref: '123')
        )
        allow(sales_order).to receive(:persist_ref!).with('123')
        allow(sales_order).to receive(:persist_current_payload!)
      end

      it 'persists the order management ref on sales order' do
        expect(interactor).to be_a_success

        expect(sales_order).to have_received(:persist_ref!).with('123')
      end

      context 'when force_delivery is true' do
        let(:interactor_contexts) { super().merge(force_delivery: true) }

        before do
          allow(sales_order).to receive(:sent?).and_return(true)
          allow(Rails.logger).to receive(:info)
        end

        it 'checks the delivery and logs a warning' do
          expect(interactor).to be_a_success

          expect(Rails.logger).to have_received(:info).with(
            I18n.t('order_management.delivery_force', reference: sales_order.attributes)
          )
        end
      end
    end

    context 'when sales order already sent' do
      let(:sales_order) { build_stubbed(:sales_order) }

      before do
        allow(sales_order).to receive(:sent?).and_return(true)
      end

      it 'checks the delivery and fails the interactor' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq(
          I18n.t('order_management.already_sent_error', reference: sales_order.attributes)
        )
      end
    end

    context 'when sales order is not able to persist the payload' do
      let(:sales_order) { build_stubbed(:sales_order) }
      let(:exception) { OrderManagement::SalesOrder::PayloadHasChanged.new('ouch') }

      before do
        allow(sales_order).to receive(:persist_current_payload!).and_raise(exception)
      end

      it 'fails the interactor' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq('ouch')
      end
    end

    context 'when post sales order does not return an order_management_ref' do
      let(:sales_order) { build_stubbed(:sales_order, last_request_payload: current_payload) }
      let(:current_payload) { { 'name' => 'payload' } }
      let(:restforce_response) { OpenStruct.new(body: 'Response') }

      before do
        allow(OrderManagement::ClientInterface).to receive(
          :post_composite_for
        ).with(current_payload, class_name: 'OrderManagement::SalesOrder').and_return(
          OpenStruct.new(response: restforce_response, order_management_ref: nil)
        )
        allow(sales_order).to receive(:persist_current_payload!)
      end

      it 'fails the interactor' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq(
          I18n.t('order_management.missing_order_management_ref', response: 'Response')

        )
      end
    end

    context 'when sales order context is blank' do
      let(:interactor_contexts) { {} }

      it 'fails' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq "SalesOrder required in #{described_class.name}"
      end
    end
  end
end
