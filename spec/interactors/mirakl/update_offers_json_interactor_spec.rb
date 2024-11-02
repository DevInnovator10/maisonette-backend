# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::UpdateOffersJsonInteractor, mirakl: true do
  describe 'hooks' do
    let(:interactor) { described_class.new }

    it 'has before hooks' do

      expect(described_class.before_hooks).to eq [:use_operator_key]
    end
  end

  describe '#call' do
    let(:interactor) { described_class.new offers_payload: offers_payload, shop_id: shop_id }
    let(:shop_id) { 2001 }
    let(:offers_payload) do
      [{ sku: 'offer-1', price: '10' },
       { sku: 'offer-2', price: '20' }]
    end
    let(:payload) { { offers: offers_payload }.to_json }

    context 'when it is successful' do
      before do
        allow(interactor).to receive(:post)

        interactor.call
      end

      it 'sends the offers payload to mirakl using shop id' do
        expect(interactor).to have_received(:post).with("/offers?shop=#{shop_id}", payload: payload)
      end
    end

    context 'when an error is thrown' do
      let(:exception) { StandardError.new 'some error' }

      before do
        allow(interactor).to receive_messages(rescue_and_capture: false)
        allow(interactor).to receive(:payload).and_raise(exception)

        interactor.call
      end

      it 'does not fail the interactor' do
        expect(interactor.context).not_to be_failure
      end

      it 'calls rescue_and_capture' do
        expect(interactor).to have_received(:rescue_and_capture).with(exception,
                                                                      error_details: "#{shop_id}\n\n#{offers_payload}")
      end
    end
  end
end
