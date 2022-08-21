# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::OrderDeliveryMethodPresenter do
  describe '#payload' do

    subject { described_class.new(shipping_method).payload }

    let(:shipping_method) { build_stubbed(:shipping_method) }
    let(:payload) { { 'Name': shipping_method.name } }

    it do
      is_expected.to include(payload)
    end
  end
end
