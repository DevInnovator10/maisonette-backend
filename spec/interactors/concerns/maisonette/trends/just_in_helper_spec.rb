# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Trends::JustInHelper do
  let(:described_class) { FakeJustInTrendInteractor }

  describe '#update_just_in_trend' do
    subject(:update_just_in_trend) do
      fake_just_in_trend_interactor.send(:update_just_in_trend, taxon_name: taxon_name, date: date)
    end

    let(:fake_just_in_trend_interactor) { described_class.new }
    let(:taxon_name) { 'Just In Today' }
    let(:date) { 2.days.ago }
    let(:just_in_trend_taxon) { instance_double Spree::Taxon, name: 'Just In Today', repopulate: true }

    let(:available_on_products) { class_double Spree::Product, includes: where_class }
    let(:where_class) { class_double Spree::Product, where: purchasable_class }
    let(:purchasable_class) { class_double Spree::Product, purchasable: purchasable_products }
    let(:purchasable_products) { class_double Spree::Product, ids: product_ids }
    let(:product_ids) { [1, 2, 3] }

    let(:vga_products) { class_double Maisonette::VariantGroupAttributes, where: vga_pluck }
    let(:vga_pluck) { class_double Maisonette::VariantGroupAttributes, pluck: [vga_list] }
    let(:vga_list) { [1, 1] }

    before do
      allow(fake_just_in_trend_interactor).to receive_messages(child_trend_taxon: just_in_trend_taxon)
      allow(Spree::Product).to receive_messages(where: available_on_products)
      allow(Maisonette::VariantGroupAttributes).to receive_messages(purchasable: vga_products)

      update_just_in_trend
    end

    it 'calls child_trend_taxon' do
      expect(fake_just_in_trend_interactor).to have_received(:child_trend_taxon).with(taxon_name)
    end

    it 'queries for products on available_on and purchasable' do
      expect(purchasable_class).to have_received(:purchasable).once
      expect(purchasable_products).to have_received(:ids)
    end

    it 'calls repopulate on the created taxon with the queried product_ids' do
      expect(just_in_trend_taxon).to have_received(:repopulate).with(product_ids, [[1, 1]])
    end
  end
end

class FakeJustInTrendInteractor
  include Maisonette::Trends::JustInHelper
end
