# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::SalesOrder, type: :model do
  it { is_expected.to belong_to(:spree_order).class_name('Spree::Order') }
  it { is_expected.to have_many(:order_item_summaries).dependent(:destroy) }
  it { is_expected.to have_one(:order_summary).dependent(:destroy) }

  describe '#payload' do
    subject(:payload) { sales_order.payload }

    let(:presenter_instance) { instance_double(OrderManagement::SalesOrderPresenter) }
    let(:sales_order) { build_stubbed(:sales_order, spree_order: spree_order) }
    let(:spree_order) { build_stubbed(:order) }
    let(:api_version) { OrderManagement::ClientInterface.api_version }

    before do
      allow(OrderManagement::SalesOrderPresenter).to receive(:new).with(
        spree_order,
        api_version
      ).and_return(presenter_instance)
      allow(presenter_instance).to receive(:payload)
    end

    it 'calls the sales order presenter' do
      payload

      expect(presenter_instance).to have_received(:payload)
    end
  end

  describe '.reference_id' do
    subject(:reference_id) { OrderManagement::SalesOrder.reference_id }

    it { is_expected.to eq 'refOrder' }
  end

  describe '#sent?' do
    context 'when last_request_payload and order_management_ref are present' do
      subject(:sent?) { sales_order.sent? }

      let(:sales_order) { build_stubbed(:sales_order, last_request_payload: { a: 1 }, order_management_ref: '123') }

      it 'returns true' do
        expect(sent?).to eq true
      end
    end
  end

  describe '#persist_ref!' do
    subject(:persist_ref!) { sales_order.persist_ref!('123') }

    let(:sales_order) { create(:sales_order, spree_order_id: order.id) }
    let(:order) { create(:order) }

    it 'updates the order_management_ref' do
      expect { persist_ref! }.to change(sales_order, :order_management_ref).from(nil).to('123')
    end

    it 'create a OrderManagement::Commands::QueryOrderSummary' do
      expect { persist_ref! }.to change(OrderManagement::Commands::QueryOrderSummary, :count).from(0)

      command = OrderManagement::Commands::QueryOrderSummary.last
      expect(command.order_management_ref).to eq '123'
      expect(command.data).to eq('spree_order_id' => order.id)
    end

    it 'create a OrderManagement::Commands::QueryOrderItemSummary' do
      expect { persist_ref! }.to change(OrderManagement::Commands::QueryOrderItemSummary, :count).from(0)

      command = OrderManagement::Commands::QueryOrderItemSummary.last
      expect(command.order_management_ref).to eq '123'
      expect(command.data).to eq('spree_order_id' => order.id)
    end
  end

  describe '#persist_current_payload!' do
    subject(:persist_current_payload!) { sales_order.persist_current_payload! }

    let(:sales_order) { create(:sales_order) }

    before { allow(sales_order).to receive(:payload).and_return(a: 1) }

    it 'updates the order_management_ref' do
      expect { persist_current_payload! }.to change(sales_order, :last_request_payload).from({})
    end

    context 'when payload has changed' do
      let(:sales_order) { build_stubbed(:sales_order, last_request_payload: { a: 1 }) }

      before { allow(sales_order).to receive(:payload).and_return(diff: 2) }

      it 'raise an exception' do
        expect { persist_current_payload! }.to raise_error(OrderManagement::SalesOrder::PayloadHasChanged)
      end
    end

    context 'when payload is not changed' do
      let(:sales_order) { create(:sales_order, last_request_payload: { 'a' => 1 }) }

      it 'updates the order_management_ref' do
        expect { persist_current_payload! }.not_to change(sales_order, :last_request_payload).from('a' => 1)
      end
    end
  end

  describe '#forward_complete!' do
    subject(:forward_complete!) { sales_order.forward_complete! }

    context 'when all compliant' do
      let(:sales_order) do
        create(
          :sales_order,
          order_item_summaries: order_item_summaries,
          last_request_payload: { tet: 1 },
          order_management_ref: '123',
          spree_order: spree_order
        )
      end
      let(:spree_order) { create(:order_with_line_items) }
      let(:order_item_summaries) do
        [
          create(:order_item_summary, order_management_ref: '123', summarable: spree_order.line_items.first),
          create(:order_item_summary, order_management_ref: '456', summarable: spree_order.shipments.first)
        ]
      end

      it 'touches completed_at' do
        expect { forward_complete! }.to change(sales_order, :completed_at).from(nil)
      end
    end

    context 'when is not sent' do
      let(:sales_order) { build_stubbed(:sales_order) }

      before { allow(sales_order).to receive(:sent?).and_return(false) }

      it 'raise an error' do
        expect { forward_complete! }.to raise_error(OrderManagement::SalesOrder::CannnotCompletNotSent)
      end
    end

    context 'when has not order items summaries' do
      let(:sales_order) { build_stubbed(:sales_order) }

      before { allow(sales_order).to receive(:sent?).and_return(true) }

      it 'raise an error' do
        expect { forward_complete! }.to raise_error(OrderManagement::SalesOrder::MissingOrInvalidOrderItemSummaries)
      end
    end

    context 'when order items do not equal spree line items' do
      let(:sales_order) do
        create(
          :sales_order,
          order_item_summaries: [order_item_summary],
          last_request_payload: { tet: 1 },
          order_management_ref: '123',
          spree_order: spree_order
        )
      end
      let(:spree_order) { create(:order_with_line_items, line_items_count: 2) }
      let(:order_item_summary) do
        create(:order_item_summary, order_management_ref: '123', summarable: spree_order.line_items.first)
      end

      it 'raise an error' do
        expect { forward_complete! }.to raise_error(OrderManagement::SalesOrder::MissingOrInvalidOrderItemSummaries)
      end
    end

    context 'when order items have not order_management_ref' do
      let(:sales_order) do
        create(
          :sales_order,
          order_item_summaries: [order_item_summary],
          last_request_payload: { tet: 1 },
          order_management_ref: '123',
          spree_order: spree_order
        )
      end
      let(:spree_order) { create(:order_with_line_items) }
      let(:order_item_summary) do
        create(:order_item_summary, summarable: spree_order.line_items.first)
      end

      it 'raise an error' do
        expect { forward_complete! }.to raise_error(OrderManagement::SalesOrder::MissingOrInvalidOrderItemSummaries)
      end
    end

    context 'when order items do not equal shipments' do
      let(:sales_order) do
        create(
          :sales_order,
          order_item_summaries: order_item_summaries,
          last_request_payload: { tet: 1 },
          order_management_ref: '123',
          spree_order: spree_order
        )
      end
      let(:spree_order) { create(:order_with_line_items) }
      let(:order_item_summaries) do
        [
          create(:order_item_summary, order_management_ref: '123', summarable: spree_order.line_items.first),
          create(:order_item_summary, order_management_ref: '456', summarable: spree_order.shipments.first)
        ]
      end

      before do
        order_item_summaries
        spree_order.shipments.last.destroy!
        spree_order.reload
      end

      it 'raise an error' do
        expect { forward_complete! }.to raise_error(OrderManagement::SalesOrder::MissingOrInvalidOrderItemSummaries)
      end
    end
  end
end
