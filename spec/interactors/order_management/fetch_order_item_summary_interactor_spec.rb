# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::FetchOrderItemSummaryInteractor do
    subject(:interactor) { described_class.call(interactor_contexts) }

  let(:interactor_contexts) { { sales_order: sales_order } }
  let(:order) { create(:order_with_line_items, line_items_count: 1) }
  let(:sales_order) { create(:sales_order, order_item_summaries: [order_item_summary]) }
  let(:line_item) { order.line_items.first }
  let(:order_item_summary) { create(:order_item_summary, summarable: line_item) }
  let(:client_response) do
    OpenStruct.new(
      response: instance_double(Restforce::Collection),
      items: [OpenStruct.new(External_Id__c: order_item_summary.external_id, Id: '10u1b0000004ChBAAU')]
    )
  end

  describe '#call' do
    context 'when successful' do
      before do
        allow(OrderManagement::ClientInterface).to receive(:query_object_ids_by).with(
          [order_item_summary.external_id], 'OrderItemSummary'
        ).and_return(client_response)
        allow(sales_order).to receive(:forward_complete!)
      end

      it 'creates the corresponding order management item summaries' do
        expect { interactor }.to change { order_item_summary.reload.order_management_ref }
          .from(nil).to('10u1b0000004ChBAAU')
      end

      it 'marks sales order forward process as complete' do
        interactor

        expect(sales_order).to have_received(:forward_complete!)
      end
    end

    context 'when cannot locate the item summary' do
      before do
        allow(GlobalID::Locator).to receive(:locate).and_return(nil)
        allow(OrderManagement::ClientInterface).to receive(:query_object_ids_by).with(
          [order_item_summary.external_id], 'OrderItemSummary'
        ).and_return(client_response)
      end

      it 'creates the corresponding order management item summaries' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq(
          I18n.t('order_management.unable_to_locate_item_summary', item_summary: client_response.items.first)
        )
      end
    end

    context 'when order item response is empty' do
      let(:client_response) do
        OpenStruct.new(
          response: instance_double(Restforce::Collection),
          items: []
        )
      end

      before do
        allow(OrderManagement::ClientInterface).to receive(:query_object_ids_by).with(
          [order_item_summary.external_id], 'OrderItemSummary'
        ).and_return(client_response)
      end

      it 'creates the corresponding order management item summaries' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq(
          I18n.t('order_management.order_item_summary_empty', response: client_response.response)
        )
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
end
