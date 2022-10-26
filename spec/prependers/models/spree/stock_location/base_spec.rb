# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::StockLocation::Base, type: :model do
    let(:described_class) { Spree::StockLocation }

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe '#maisonette_fulfillment?' do
    subject { stock.maisonette_fulfillment? }

    let(:stock) { build(:stock_location, name: 'Maisonette Fulfillment') }

    it { is_expected.to be_truthy }
  end
end
