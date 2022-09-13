# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Shipment::Vendor, type: :model do
    let(:described_class) { Spree::Shipment }

  it { is_expected.to delegate_method(:vendor).to(:stock_location) }
end
