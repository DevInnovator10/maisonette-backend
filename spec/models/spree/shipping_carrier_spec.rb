# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::ShippingCarrier do
  describe 'validation' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_presence_of(:easypost_carrier_id) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:shipping_method_carriers).dependent(:destroy) }
    it { is_expected.to have_many(:shipping_methods).through(:shipping_method_carriers) }
  end
end
