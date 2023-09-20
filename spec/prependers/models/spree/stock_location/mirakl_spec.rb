# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::StockLocation::Mirakl, type: :model, mirakl: true do
  let(:described_class) { Spree::StockLocation }

  describe 'associations' do
    it { is_expected.to have_one(:mirakl_shop).through(:vendor) }
  end

  describe '#restock_inventory' do
    subject { described_class.new.restock_inventory }

    it { is_expected.to be_falsey }
  end

  describe '#restock_inventory?' do
    subject { described_class.new.restock_inventory? }

    it { is_expected.to be_falsey }
  end
end
