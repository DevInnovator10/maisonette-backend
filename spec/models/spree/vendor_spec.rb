# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Vendor, type: :model do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_uniqueness_of(:avalara_code) }
  it { is_expected.to have_many(:prices) }
  it { is_expected.to have_many(:line_items) }
  it { is_expected.to belong_to(:mirakl_shop).optional }
  it { is_expected.to delegate_method(:country_iso).to(:stock_location).allow_nil }
  it { is_expected.to delegate_method(:domestic_override).to(:stock_location).allow_nil }

  describe '.default' do
    it 'returns maisonette default vendor' do
      expect(described_class.default.name).to eq 'Maisonette'

      expect(described_class.default.avalara_code).to eq 'Maisonette'
    end
  end

  describe '#estimated_giftwrap_price' do
    subject { vendor.estimated_giftwrap_price }

    let(:vendor) { build_stubbed(:vendor) }

    it { is_expected.to be 5.00 }

    context 'when giftwrap_price is set' do
      let(:vendor) { build_stubbed(:vendor, giftwrap_price: 10) }

      it { is_expected.to be 10.00 }
    end
  end
end
