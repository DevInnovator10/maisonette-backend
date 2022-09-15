# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order::Marketplace, type: :model do
    let(:described_class) { Spree::Order }

  describe '#item_from_same_vendor' do
    subject { line_item.order.item_from_same_vendor(line_item, options) }

    let(:line_item) { build(:line_item) }

    context 'when comparing by options vendor_id' do
      context 'when options vendor is nil' do
        let(:options) { { options: { vendor_id: nil } } }

        it 'raises OptionVendorIdRequired' do
          expect { line_item.order.item_from_same_vendor(line_item, options) }
            .to raise_exception Spree::Order::OptionVendorIdRequired
        end
      end

      context 'when argument vendor is equal to line item vendor' do
        let(:options) { { options: { vendor_id: line_item.vendor_id } } }

        it { is_expected.to be_truthy }
      end

      context 'when argument vendor is not equal to line item vendor' do
        let(:options) { { options: { vendor_id: 0 } } }

        it { is_expected.to be_falsey }
      end
    end

    context 'when comparing by vendor_id' do
      context 'when vendor_id is nil' do
        let(:options) { { 'vendor_id': nil } }

        it 'raises OptionVendorIdRequired' do
          expect { line_item.order.item_from_same_vendor(line_item, options) }
            .to raise_exception Spree::Order::OptionVendorIdRequired
        end
      end

      context 'when argument vendor is equal to line item vendor' do
        let(:options) { { 'vendor_id' => line_item.vendor_id } }

        it { is_expected.to be_truthy }
      end

      context 'when argument vendor is not equal to line item vendor' do
        let(:options) { { 'vendor_id' => 0 } }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#find_line_item_by_variant' do
    let(:order) { build(:order_with_line_items) }
    let(:price) { build(:price) }
    let(:line_item) { order.line_items.first }
    let(:variant) { line_item.variant }

    before { variant.prices << price }

    context 'when same vendor id' do
      subject { order.find_line_item_by_variant(variant, options: { vendor_id: line_item.vendor_id }) }

      it { is_expected.to eq line_item }
    end

    context 'when different vendor' do
      subject { order.find_line_item_by_variant(variant, options: { vendor_id: 0 }) }

      it { is_expected.to be_nil }
    end
  end
end
