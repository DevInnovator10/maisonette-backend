# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::UpdateFulfillmentOrderInteractor do
  subject(:interactor) { described_class.call(context) }

  let(:context) { { mirakl_order_id: mirakl_order_id, status: status } }

  let(:mirakl_order_id) { '12345' }
  let(:status) { 'Assigned' }

  describe '#call' do
    context 'when successful' do
      before do
        allow(OrderManagement::ClientInterface).to receive(:upsert!)
      end

      it 'calls OrderManagement::ClientInterface#upsert! with correct params' do
        interactor

        expect(OrderManagement::ClientInterface).to have_received(:upsert!).with(
          'FulfillmentOrder', 'Mirakl_Order_ID__c',
          'Status' => status, 'Mirakl_Order_ID__c' => mirakl_order_id
        )
      end
    end

    context 'when mirakl_order_id context is nil' do
      let(:mirakl_order_id) { nil }

      it 'fails' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq "Mirakl Order ID required in #{described_class.name}"
      end
    end

    context 'when status context is nil' do
      let(:status) { nil }

      it 'fails' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq "Status required in #{described_class.name}"
      end
    end

    context 'when OrderManagement::ClientInterface raises an exception' do
      before do
        allow(OrderManagement::ClientInterface).to(
          receive(:upsert!)
            .and_raise(::Restforce::ErrorCode::FieldIntegrityException, 'Error message')
        )
      end

      it 'fails' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq 'Error message'
      end
    end
  end
end
