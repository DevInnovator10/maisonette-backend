# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Store::EnabledShippingServiceLevels, type: :model do
  let(:described_class) { Spree::Store }

  it 'provides a enabled_shipping_service_levels as array' do
    expect(described_class.new.enabled_shipping_service_levels).to be_kind_of Array
  end
end
