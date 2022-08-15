# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Trends::BestSellersHelper do
  let(:described_class) { FakeBestSellersTrendInteractor }

  describe '#update_best_sellers_trend' do
    subject(:update_best_sellers_trend) do
      fake_best_sellers_trend_interactor.send(:update_best_sellers_trend, taxon_name: taxon_name, date: date)
    end

    let(:fake_best_sellers_trend_interactor) { described_class.new }
    let(:taxon_name) { 'Selling Fast Today' }
    let(:date) { 2.days.ago }
    let(:selling_fast_trend_taxon) { instance_double Spree::Taxon, name: 'Selling Fast Today', repopulate: true }

    let(:best_selling_product) { order_2.products[0] }
    let(:second_best_selling_product) { order_1.products[0] }
    let(:order_1) { create :completed_order_with_totals }
    let(:order_2) { create :completed_order_with_totals }

    let(:vga_products) { class_double Maisonette::VariantGroupAttributes, where: vga_purchasable }
    let(:vga_purchasable) { class_double Maisonette::VariantGroupAttributes, purchasable: vga_group }
    let(:vga_group) { class_double Maisonette::VariantGroupAttributes, group: vga_order }
    let(:vga_order) { class_double Maisonette::VariantGroupAttributes, order: vga_pluck }
    let(:vga_pluck) { class_double Maisonette::VariantGroupAttributes, pluck: [vga_list] }
    let(:vga_list) { [1, 1] }

    before do
      allow(fake_best_sellers_trend_interactor).to receive_messages(child_trend_taxon: selling_fast_trend_taxon)
      allow(Maisonette::VariantGroupAttributes).to receive_messages(joins: vga_products)

      order_1
      order_2
      best_selling_product.variants[0].stock_items[0].update_column('count_on_hand', 100)
      second_best_selling_product.variants[0].stock_items[0].update_column('count_on_hand', 100)

      20.times do
        line_item = create :line_item, product: best_selling_product
        create :completed_order_with_totals, line_items: [line_item]
      end

      line_item = create :line_item, product: second_best_selling_product
      create :completed_order_with_totals, line_items: [line_item]

      update_best_sellers_trend
    end

    it 'calls child_trend_taxon' do
      expect(fake_best_sellers_trend_interactor).to have_received(:child_trend_taxon).with(taxon_name)
    end

    it 'calls repopulate on the created taxon with the top 5% previously purchased and currently purchasable products' \
       'ordered by number of times purchased' do
      expect(selling_fast_trend_taxon).to have_received(:repopulate).with([best_selling_product.id,
                                                                           second_best_selling_product.id],
                                                                          [[1, 1]])
    end
  end
end

class FakeBestSellersTrendInteractor
  include Maisonette::Trends::BestSellersHelper
end
