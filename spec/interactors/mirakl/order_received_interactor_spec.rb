# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::OrderReceivedInteractor, mirakl: true do
  describe '#call' do
    let(:interactor) { described_class.new logistic_order_id: logistic_order_id }
    let(:logistic_order_id) { 'R123-A' }

    before do

      allow(interactor).to receive(:put)

      interactor.call
    end

    it 'calls put /orders/:id/receive' do
      expect(interactor).to have_received(:put).with("/orders/#{logistic_order_id}/receive")
    end
  end
end
