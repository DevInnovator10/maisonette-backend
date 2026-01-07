# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::SubmitCommercialOrder::PostCommercialOrderToMirakl, mirakl: true do
  describe 'call' do
    let(:interactor) do
      described_class.new(commercial_order: commercial_order, commercial_order_payload: commercial_order_payload)
    end
    let(:context) { interactor.call }
    let(:commercial_order) do
      instance_double(Mirakl::CommercialOrder, submitted!: true, id: 5)
    end
    let(:commercial_order_payload) { 'some json payload' }
    let(:response) { instance_double(RestClient::Response, body: 'order response') }

    before do
      allow(interactor).to receive_messages(post: response, offers_not_shippable: true)
      allow(Mirakl::CreateSubmittedOrdersInteractor).to receive(:call)
    end

    context 'when it is successful' do
      before { context }

      it 'calls post to /orders' do
        expect(interactor).to have_received(:post).with('/orders', payload: commercial_order_payload)
      end

      context 'when the response is successful' do
        it 'calls #submitted! on the commercial order' do
          expect(commercial_order).to have_received(:submitted!)
        end

        it 'calls Mirakl::CreateSubmittedOrdersInteractor' do
          expect(Mirakl::CreateSubmittedOrdersInteractor).to(
            have_received(:call).with(mirakl_orders_response: response.body,
                                      commercial_order: commercial_order)
          )
        end
      end
    end

    context 'when it fails' do
      let(:interactor) { described_class.new }
      let(:exception) { StandardError.new 'foo' }

      before do
        allow(interactor).to receive(:handle_exception)
        allow(interactor).to receive(:context).and_raise(exception)

        interactor.call
      end

      it 'calls #handle_exception' do
        expect(interactor).to have_received(:handle_exception).with(exception)
      end
    end
  end

  describe 'offers_not_shippable' do
    subject(:offers_not_shippable) { interactor.send :offers_not_shippable }

    let(:interactor) { described_class.new(commercial_order: commercial_order, response: response) }
    let(:commercial_order) { instance_double(Mirakl::CommercialOrder, :error_message= => true) }

    let(:response) { { 'offers_not_shippable' => offers }.to_json }

    context 'when offers are not present' do
      let(:offers) { [] }

      it 'does not raise an exception' do
        expect { offers_not_shippable }.not_to raise_exception
      end
    end

    context 'when offers are present' do
      let(:offers) { [{ 'error_code' => 'product_not_available', 'offer_id' => '2001' }] }

      it 'raises an exception' do
        expect { offers_not_shippable }.to raise_exception(described_class::OffersNotShippable)
      end
    end
  end
end
