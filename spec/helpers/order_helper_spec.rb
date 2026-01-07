# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderHelper do
  let(:order_with_shipment) { create(:order_with_line_items, item_total: 200) }

  before { assign(:order, order_with_shipment) }

  describe '#monogram_color_display_name' do
    subject { helper.monogram_color_display_name(line_item_monogram.line_item) }

    let(:line_item_monogram) do
      create :line_item_monogram, customization: customization, with_offer_settings: offer_settings
    end
    let(:offer_settings) do
      create :offer_settings,
             :with_monogram_customizations,
             monogrammable: true,
             monogram_price: 8.99,
             monogram_cost_price: 2.99,
             monogram_max_text_length: 32,
             final_sale: true
    end

    let(:color_customization) { { 'name' => 'White', 'value' => '#ffffff' } }
    let(:customization) do
      { 'font' => { 'name' => 'Toy Soilder', 'value' => 'serif' }, 'color' => color_customization }
    end

    context 'when the line item monogram should be white' do
      it { is_expected.to eq 'White' }
    end

    context 'when the line item monogram should be red' do
      let(:color_customization) { { 'name' => 'Red', 'value' => '#FF0000' } }

      it { is_expected.to eq 'Red' }
    end

    context 'when offer settings do not exist' do
      before { allow(line_item_monogram.line_item.variant).to receive(:offer_settings_for_vendor) }

      it { is_expected.to eq 'White' }
    end

    context 'without a matching color selection' do
      let(:custom) do
        { 'font' => { 'name' => 'Toy Soilder', 'value' => 'serif' },
          'color' => { 'name' => 'Foo Bar', 'value' => '#ffffff' } }
      end

      before do
        line_item_monogram.update_column(:customization, custom)
        line_item_monogram.line_item.reload
      end

      it { is_expected.to eq 'Foo Bar' }
    end
  end

  describe '#order_subtotals' do
    let(:subtotals) { helper.order_subtotals(order_with_shipment) }

    it 'is an array of hashes' do
      expect(subtotals).to be_a Array
      expect(subtotals.all? { |r| r.is_a? Hash }).to be true
    end

    it 'has the item subtotal' do
      subtotal = subtotals.first
      expect(subtotal[:label]).to eq 'Subtotal'
      expect(subtotal[:value].to_s).to eq order_with_shipment.display_item_total.to_s
    end

    it 'has no duplicate entries' do
      3.times { helper.order_subtotals(order_with_shipment) }
      uniq = subtotals.map { |s| s[:label] }.uniq.length == subtotals.length
      expect(uniq).to be true
    end

    it 'only includes tax with tax adjustments' do
      tax_rate = create(:tax_rate, name: 'Default')
      tax_adjustment = create :adjustment, source: tax_rate, order: order_with_shipment
      tax_subtotal = subtotals.detect { |hash| hash[:label] == 'Tax' }

      expect(tax_subtotal).to be_present
      expect(tax_subtotal[:value]).to eq Spree::Money.new(tax_adjustment.amount).to_s
    end

    it 'only includes giftwrap if order has giftwrap' do
      giftwrap_total = Spree::Money.new(200)
      allow(order_with_shipment).to receive_messages(has_giftwrap?: true, giftwrap_total: giftwrap_total)
      giftwrap_subtotal = subtotals.detect { |hash| hash[:label] == 'Gift Wrapping' }

      expect(giftwrap_subtotal).to be_present
      expect(giftwrap_subtotal[:value]).to eq giftwrap_total.to_s
    end

    it 'only includes shipments if shipping amount including adjustments is positive' do
      order_with_shipment.update(shipment_total: 0)
      shipments_subtotal = subtotals.detect { |hash| hash[:label] == 'Shipping' }
      expect(shipments_subtotal).not_to be_present

      shipment = order_with_shipment.shipments.first
      create :adjustment, source: shipment, adjustable: shipment, order: order_with_shipment, amount: 20
      shipments_subtotal = helper.order_subtotals(order_with_shipment).detect { |hash| hash[:label] == 'Shipping' }

      expect(shipments_subtotal).to be_present
      expect(shipments_subtotal[:value]).to eq Spree::Money.new(20).to_s
    end
  end
end
