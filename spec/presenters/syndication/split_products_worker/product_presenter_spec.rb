# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Syndication::SplitProductsWorker::ProductPresenter do
  shared_examples 'a product property presentation' do |property_name|
    context "when the product doesn't have a value for the presented property name" do
      it { is_expected.to be_nil }
    end

    context 'when the product has a value for the presented property name' do
      let(:property) { create :property, name: property_name, presentation: property_name }
      let(:product_property) { create :product_property, property: property, value: 'Fake property name' }
      let(:product) { create :product, product_properties: [product_property] }

      it { is_expected.to eq 'Fake property name' }
    end
  end

  shared_examples 'a taxon values presentation' do |taxon_name|
    context 'when the product has no taxons of the presented name' do
      it { is_expected.to eq [] }
    end

    context 'when the product has one taxon of the presented name' do
      let(:taxonomy) { create :taxonomy, taxon_name }
      let(:taxon_0) { taxonomy.taxons.first }
      let(:taxon_1) do
        create :taxon, taxonomy: taxonomy, name: 'Fake taxon', parent: taxon_0
      end
      let(:product) { create :product, taxons: [taxon_1] }

      it { is_expected.to eq ['Fake taxon'] }
    end

    context 'when the product has two taxons of the presented name' do
      let(:taxonomy) { create :taxonomy, taxon_name }
      let(:taxon_0) { taxonomy.taxons.first }
      let(:taxon_1_0) do
        create :taxon, taxonomy: taxonomy, name: 'Fake taxon 0', parent: taxon_0
      end
      let(:taxon_1_1) do
        create :taxon, taxonomy: taxonomy, name: 'Fake taxon 1', parent: taxon_0
      end
      let(:product) { create :product, taxons: [taxon_1_0, taxon_1_1] }

      it { is_expected.to eq ['Fake taxon 0', 'Fake taxon 1'] }
    end
  end

  shared_examples 'an exists in trends presentation' do |trend_name|
    context "when the product isn't in the presented trends taxon" do
      it { is_expected.to eq false }
    end

    context 'when the product is in the presented trends taxon' do
      context 'when the product has one taxon of the presented name' do
        let(:taxonomy) { create :taxonomy, :trends }
        let(:taxon_0) { taxonomy.taxons.first }
        let(:taxon_1) do
          create :taxon, taxonomy: taxonomy, name: trend_name, parent: taxon_0
        end
        let(:product) { create :product, taxons: [taxon_1] }

        it { is_expected.to eq true }
      end
    end
  end

  subject { |example| described_instance.public_send example.metadata[:described_method] }

  let(:product) { build_stubbed :product }
  let(:described_instance) { described_class.new(product) }

  describe 'constants' do
    subject { described_class }

    it { is_expected.to be_const_defined(:SIZE_BROKEN_THRESHOLD) }
  end

  describe '#present_maisonette_product_id', described_method: :present_maisonette_product_id do
    it_behaves_like 'a product property presentation', 'Maisonette Product ID'
  end

  describe '#present_maisonette_sku', described_method: :present_maisonette_sku do
    let(:master_variant) { create :master_variant, sku: 'Fake master variant SKU' }
    let(:product) { master_variant.product }

    it { is_expected.to eq 'Fake master variant SKU' }
  end

  describe '#present_marketplace_sku', described_method: :present_marketplace_sku do
    let(:master_variant) { create :master_variant, sku: 'Fake master variant SKU' }
    let(:product) { master_variant.product }

    it { is_expected.to eq 'Fake master variant SKU' }
  end

  describe '#present_manufacturer_id', described_method: :present_manufacturer_id do
    let(:product) { build_stubbed :product, sku: 'Fake product SKU' }

    it { is_expected.to eq 'Fake product SKU' }
  end

  describe '#present_size', described_method: :present_size do
    it { is_expected.to be_nil }
  end

  describe '#present_option_type', described_method: :present_option_type do
    it { is_expected.to be_nil }
  end

  describe '#present_product_name', described_method: :present_product_name do
    let(:product) { build_stubbed :product, name: 'Fake product name' }

    it { is_expected.to eq 'Fake product name' }
  end

  describe '#present_vendor_sku_description', described_method: :present_vendor_sku_description do
    context 'when the product has a description' do
      let(:product) { build_stubbed :product, description: 'Fake product description' }

      it { is_expected.to eq 'Fake product description' }
    end
  end

  describe '#present_image', described_method: :present_image do
    context "when the product's master variant doesn't have any images" do
      it { is_expected.to be_nil }
    end

    context "when the product's master variant has a first image" do
      let(:first_image) do
        create(:image, attachment: File.new(Rails.root.join('spec/fixtures/images/thinking-cat.jpg')))
      end
      let(:master_variant) { create :master_variant, images: [first_image] }
      let(:product) { master_variant.product }

      it { is_expected.to include '/product_large/thinking-cat.jpg' }
    end

    context "when the product's master variant has multiple images" do
      let(:first_image) do
        create(:image, attachment: File.new(Rails.root.join('spec/fixtures/images/thinking-cat.jpg')))
      end
      let(:master_variant) { create :master_variant, images: [first_image, create(:image), create(:image)] }
      let(:product) { master_variant.product }

      it { is_expected.to include '/product_large/thinking-cat.jpg' }
    end
  end

  describe '#present_side_image', described_method: :present_side_image do
    context "when the product's master variant doesn't have any images" do
      it { is_expected.to be_nil }
    end

    context "when the product's master variant has a first image but not a second image" do
      let(:master_variant) { create :master_variant, images: [create(:image)] }
      let(:product) { master_variant.product }

      it { is_expected.to be_nil }
    end

    context "when the product's master variant has a first and a second image" do
      let(:second_image) do
        create(:image, attachment: File.new(Rails.root.join('spec/fixtures/images/thinking-cat.jpg')))
      end
      let(:master_variant) { create :master_variant, images: [create(:image), second_image] }
      let(:product) { master_variant.product }

      it { is_expected.to include '/product_large/thinking-cat.jpg' }
    end

    context "when the product's master variant has multiple images" do
      let(:second_image) do
        create(:image, attachment: File.new(Rails.root.join('spec/fixtures/images/thinking-cat.jpg')))
      end
      let(:master_variant) { create :master_variant, images: [create(:image), second_image, create(:image)] }
      let(:product) { master_variant.product }

      it { is_expected.to include '/product_large/thinking-cat.jpg' }
    end
  end

  describe '#present_maisonette_retail', described_method: :present_maisonette_retail do
    it { is_expected.to be_nil }
  end

  describe '#present_maisonette_sale', described_method: :present_maisonette_sale do
    it { is_expected.to be_nil }
  end

  describe '#present_price_min', described_method: :present_price_min do
    let(:product) do
      create(:product).tap do |product|
        create :variant, :with_multiple_prices, :in_stock,
               count_on_hand: 10,
               product: product,
               vendor_prices: [{ vendor: create(:vendor), amount: 10 }]
        create :variant, :with_multiple_prices, :in_stock,
               count_on_hand: 10,
               product: product,
               vendor_prices: [{ vendor: create(:vendor), amount: 20 }]
      end
    end

    it { is_expected.to eq 10.0 }
  end

  describe '#present_price_max', described_method: :present_price_max do
    let(:product) do
      create(:product).tap do |product|
        create :variant, :with_multiple_prices, :in_stock,
               count_on_hand: 10,
               product: product,
               vendor_prices: [{ vendor: create(:vendor), amount: 10 }]
        create :variant, :with_multiple_prices, :in_stock,
               count_on_hand: 10,
               product: product,
               vendor_prices: [{ vendor: create(:vendor), amount: 20 }]
      end
    end

    it { is_expected.to eq 20.0 }
  end

  describe '#present_boutique', described_method: :present_boutique do
    it { is_expected.to be_nil }
  end

  describe '#present_inventory', described_method: :present_inventory do
    context 'when the product has no stock items with count_on_hand > 0' do
      let(:variant) { create :variant, :with_multiple_prices, :out_of_stock }
      let(:product) { variant.product }

      it { is_expected.to eq 0 }
    end

    context 'when the product has one variant with stock items with count_on_hand > 0' do
      let(:variant) { create :variant, :with_multiple_prices, :in_stock, count_on_hand: 10 }
      let(:product) { variant.product }

      it { is_expected.to eq 10 }
    end

    context 'when the product has two variants with stock items with count_on_hand > 0' do
      let(:product) do
        create(:product).tap do |product|
          create_list :variant, 2, :with_multiple_prices, :in_stock, count_on_hand: 10, product: product
        end
      end

      it { is_expected.to eq 20 }
    end

    context 'when the product has two variants, the first one with stock items with count_on_hand > 0' \
            ', the second one not purchasable' do
      let(:product) do
        create(:product).tap do |product|
          create :variant, :with_multiple_prices, :in_stock, count_on_hand: 10, product: product
          create :variant, :in_stock, count_on_hand: 10, product: product
        end
      end

      it { is_expected.to eq 10 }
    end
  end

  describe '#present_in_stock', described_method: :present_in_stock do
    it { is_expected.to be_nil }
  end

  describe '#present_discontinue', described_method: :present_discontinue do
    context 'when product is discontinued' do
      before { product.available_until = 1.month.ago }

      it { is_expected.to be true }
    end

    context 'when product is available' do
      before { product.available_until = 1.month.from_now }

      it { is_expected.to be false }
    end
  end

  describe '#present_inventory_status', described_method: :present_inventory_status do
    context 'when the product has no stock items with count_on_hand > 0' do
      let(:variant) { create :variant, :with_multiple_prices }
      let(:product) { variant.product }

      it { is_expected.to eq 'Out of Stock' }
    end

    context "when the product's in stock stock items total is 100% of product's stock items total" \
            ' but the variant is not purchasable' do
      let(:variant) { create :variant, :with_multiple_prices, :in_stock, count_on_hand: 10, vendor_prices: [] }
      let(:product) { variant.product }

      it { is_expected.to eq 'Out of Stock' }
    end

    context "when the product's in stock stock items total is 100% of product's stock items total" do
      let(:variant) { create :variant, :with_multiple_prices, :in_stock, count_on_hand: 10 }
      let(:product) { variant.product }

      it { is_expected.to eq 'In Stock' }
    end

    context "when the product's in stock stock items total is 50% of product's stock items total" do
      let(:product) do
        create(:product).tap do |product|
          create :variant, :with_multiple_prices, :in_stock, count_on_hand: 10, product: product
          create :variant, :with_multiple_prices, :out_of_stock, product: product
        end
      end

      it { is_expected.to eq 'Low Inventory' }
    end

    context "when the product's in stock stock items total is 50% of product's stock items total" \
            ' but the stock items that are out of stock are not purchasable' do
      let(:product) { create :product }
      let(:in_stock_variant) { create :variant, :with_multiple_prices, :in_stock, count_on_hand: 10, product: product }
      let(:out_of_stock_variant) { create :variant, :with_multiple_prices, :out_of_stock, product: product }

      before do
        in_stock_variant
        out_of_stock_variant.prices.each(&:really_destroy!)
      end

      it { is_expected.to eq 'In Stock' }
    end
  end

  describe '#present_percent_off', described_method: :present_percent_off do
    context 'when the product has no variants with discounted prices' do
      it { is_expected.to eq '' }
    end

    context 'when the product has two variants but one variant is not purchasable' do
      let(:product) do
        create(:product).tap do |product|
          create :variant, :with_multiple_prices, :in_stock, product: product
          create :variant, :with_multiple_prices, :in_stock, product: product, vendor_prices: []
        end
      end

      before { product.variants.map(&:prices) }

      it { is_expected.to eq '' }
    end

    context 'when the product has one variant with one discounted price' do
      let(:variant) do
        create(:variant,
               :with_multiple_prices,
               :in_stock,
               vendor_prices: [{ vendor: create(:vendor), amount: 100 }]).tap do |variant|
          price = variant.prices.first
          price.put_on_sale(price.amount - 20)
        end
      end
      let(:product) { variant.product }

      it { is_expected.to eq '20% Off' }
    end

    context 'when the product has one variant with more discounted prices' do
      let(:variant) do
        create(:variant,
               :with_multiple_prices,
               :in_stock,
               vendor_prices: [
                 { vendor: create(:vendor), amount: 100 },
                 { vendor: create(:vendor), amount: 100 }
               ]).tap do |variant|
          price = variant.prices.first
          variant.prices.first.put_on_sale(price.amount - 10)

          price = variant.prices.second
          variant.prices.second.put_on_sale(price.amount - 20)
        end
      end
      let(:product) { variant.product }

      it { is_expected.to eq '20% Off' }
    end

    context 'when the product has more variants with more discounted prices' do
      let(:product) { create :product }

      before do
        create(:variant,
               :with_multiple_prices,
               :in_stock,
               product: product,
               vendor_prices: [
                 { vendor: create(:vendor), amount: 100 },
                 { vendor: create(:vendor), amount: 100 }
               ]).tap do |variant|
          price = variant.prices.first
          variant.prices.first.put_on_sale(price.amount - 20)

          price = variant.prices.second
          variant.prices.second.put_on_sale(price.amount - 10)
        end

        create(:variant,
               :with_multiple_prices,
               :in_stock,
               product: product,
               vendor_prices: [
                 { vendor: create(:vendor), amount: 100 },
                 { vendor: create(:vendor), amount: 100 }
               ]).tap do |variant|
          price = variant.prices.first
          variant.prices.first.put_on_sale(price.amount - 15)

          price = variant.prices.second
          variant.prices.second.put_on_sale(price.amount - 5)
        end
      end

      it { is_expected.to eq '20% Off' }
    end
  end

  describe '#present_product_url', described_method: :present_product_url do
    let(:product) { build_stubbed :product, slug: 'fake-product-slug' }

    context 'with an host set in ActionMailer default options' do
      let(:host) { 'www.example.com' }

      before { allow(ActionMailer::Base.default_url_options).to receive(:[]).with(:host).and_return(host) }

      it { is_expected.to eq 'www.example.com/product/fake-product-slug' }
    end
  end

  describe '#present_brand', described_method: :present_brand do
    context 'when the product has no brands' do
      it { is_expected.to be_nil }
    end

    context 'when the product has a brand' do
      let(:product) do
        create :product,
               taxons: [
                 create(:taxon,
                        name: 'Fake brand name',
                        taxonomy: create(:taxonomy, :brand))
               ]
      end

      it { is_expected.to eq 'Fake brand name' }
    end
  end

  describe '#present_season', described_method: :present_season do
    context 'when the product has no seasons' do
      it { is_expected.to be_nil }
    end

    context 'when the product has a season' do
      let(:product) do
        create :product,
               taxons: [
                 create(:taxon,
                        name: 'Fake season name',
                        taxonomy: create(:taxonomy, :season))
               ]
      end

      it { is_expected.to eq 'Fake season name' }
    end
  end

  describe '#present_category', described_method: :present_category do
    context 'when the product has no categories' do
      it { is_expected.to eq [] }
    end

    context 'when the product has one category taxon of depth 1' do
      let(:category_taxonomy) { create :taxonomy, :category }
      let(:category_taxon_0) { category_taxonomy.taxons.first }
      let(:category_taxon_1) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 1', parent: category_taxon_0
      end
      let(:product) { create :product, taxons: [category_taxon_1] }

      it { is_expected.to eq ['Fake taxon of depth 1'] }
    end

    context 'when the product has one category taxon of depth 2' do
      let(:category_taxonomy) { create :taxonomy, :category }
      let(:category_taxon_0) { category_taxonomy.taxons.first }
      let(:category_taxon_1) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 1', parent: category_taxon_0
      end
      let(:category_taxon_2) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 2', parent: category_taxon_1
      end
      let(:product) { create :product, taxons: [category_taxon_2] }

      it { is_expected.to eq ['Fake taxon of depth 1 > Fake taxon of depth 2'] }
    end

    context 'when the product has one category taxon of depth 3' do
      let(:category_taxonomy) { create :taxonomy, :category }
      let(:category_taxon_0) { category_taxonomy.taxons.first }
      let(:category_taxon_1) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 1', parent: category_taxon_0
      end
      let(:category_taxon_2) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 2', parent: category_taxon_1
      end
      let(:category_taxon_3) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 3', parent: category_taxon_2
      end
      let(:product) { create :product, taxons: [category_taxon_3] }

      it { is_expected.to eq ['Fake taxon of depth 1 > Fake taxon of depth 2 > Fake taxon of depth 3'] }
    end

    context 'when the product has one category taxon of depth 4' do
      let(:category_taxonomy) { create :taxonomy, :category }
      let(:category_taxon_0) { category_taxonomy.taxons.first }
      let(:category_taxon_1) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 1', parent: category_taxon_0
      end
      let(:category_taxon_2) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 2', parent: category_taxon_1
      end
      let(:category_taxon_3) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 3', parent: category_taxon_2
      end
      let(:category_taxon_4) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 4', parent: category_taxon_3
      end
      let(:product) { create :product, taxons: [category_taxon_4] }

      it { is_expected.to eq ['Fake taxon of depth 1 > Fake taxon of depth 2 > Fake taxon of depth 3'] }
    end

    context 'when the product has one category taxon of depth 1 but it is hidden' do
      let(:category_taxonomy) { create :taxonomy, :category }
      let(:category_taxon_0) { category_taxonomy.taxons.first }
      let(:category_taxon_1) do
        create :taxon, :is_hidden, taxonomy: category_taxonomy, name: 'Fake taxon of depth 1', parent: category_taxon_0
      end
      let(:product) { create :product, taxons: [category_taxon_1] }

      it { is_expected.to eq [] }
    end

    context 'when the product has one category taxon of depth 2 but it is hidden' do
      let(:category_taxonomy) { create :taxonomy, :category }
      let(:category_taxon_0) { category_taxonomy.taxons.first }
      let(:category_taxon_1) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 1', parent: category_taxon_0
      end
      let(:category_taxon_2) do
        create :taxon, :is_hidden, taxonomy: category_taxonomy, name: 'Fake taxon of depth 2', parent: category_taxon_1
      end
      let(:product) { create :product, taxons: [category_taxon_2] }

      it { is_expected.to eq [] }
    end

    context 'when the product has two category taxons of depth 1' do
      let(:category_taxonomy) { create :taxonomy, :category }
      let(:category_taxon_0) { category_taxonomy.taxons.first }
      let(:category_taxon_1_0) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 1 - 1st', parent: category_taxon_0
      end
      let(:category_taxon_1_1) do
        create :taxon, taxonomy: category_taxonomy, name: 'Fake taxon of depth 1 - 2nd', parent: category_taxon_0
      end
      let(:product) { create :product, taxons: [category_taxon_1_0, category_taxon_1_1] }

      it { is_expected.to eq ['Fake taxon of depth 1 - 1st', 'Fake taxon of depth 1 - 2nd'] }
    end
  end

  describe '#present_product_type', described_method: :present_product_type do
    it_behaves_like 'a taxon values presentation', :type
  end

  describe '#present_gender', described_method: :present_gender do
    it_behaves_like 'a taxon values presentation', :gender
  end

  describe '#present_available_on', described_method: :present_available_on do
    context 'when the product has no available_on value' do
      let(:product) { build_stubbed :product, available_on: nil }

      it { is_expected.to be_nil }
    end

    context 'when the product has a available_on value' do
      let(:product) { build_stubbed :product, available_on: Time.zone.at(0) }

      it { is_expected.to eq '1970-01-01 00:00:00.000000000 +0000' }
    end
  end

  describe '#present_color', described_method: :present_color do
    it_behaves_like 'a taxon values presentation', :color
  end

  describe '#present_age_range', described_method: :present_age_range do
    let(:taxon_name) { :age_range }

    context 'when the product has no taxons of the presented name' do
      it { is_expected.to eq [] }
    end

    context 'when the product has one taxon of the presented name' do
      let(:taxonomy) { create :taxonomy, taxon_name }
      let(:taxon_0) { taxonomy.taxons.first }
      let(:taxon_1) do
        create :taxon, taxonomy: taxonomy, name: 'Fake taxon', parent: taxon_0
      end
      let(:product) { create :product, taxons: [taxon_1] }

      it { is_expected.to eq ['Fake taxon'] }
    end

    context 'when the product has two taxons of the presented name' do
      let(:taxonomy) { create :taxonomy, taxon_name }
      let(:taxon_0) { taxonomy.taxons.first }
      let(:taxon_1_0) do
        create :taxon, taxonomy: taxonomy, name: 'Fake taxon 0', parent: taxon_0
      end
      let(:taxon_1_1) do
        create :taxon, taxonomy: taxonomy, name: 'Fake taxon 1', parent: taxon_0
      end
      let(:product) { create :product, taxons: [taxon_1_0, taxon_1_1] }

      it { is_expected.to eq ['Fake taxon 0', 'Fake taxon 1'] }
    end
  end

  describe '#present_clothing_sizes', described_method: :present_clothing_sizes do
    it { is_expected.to be_nil }
  end

  describe '#present_shoe_sizes', described_method: :present_shoe_sizes do
    it { is_expected.to be_nil }
  end

  describe '#present_material', described_method: :present_material do
    it_behaves_like 'a product property presentation', 'Material'
  end

  describe '#present_on_sale', described_method: :present_on_sale do
    before { allow(product).to receive(:on_sale?).and_return(true) }

    it { is_expected.to be true }
  end

  describe '#present_on_best_seller', described_method: :present_best_seller do
    it_behaves_like 'an exists in trends presentation', 'Best Sellers'
  end

  describe '#present_selling_fast', described_method: :present_selling_fast do
    it_behaves_like 'an exists in trends presentation', 'Selling Fast'
  end

  describe '#present_new', described_method: :present_new do
    it_behaves_like 'an exists in trends presentation', 'Just In'
  end

  describe '#present_exclusive', described_method: :present_exclusive do
    it_behaves_like 'an exists in trends presentation', 'Exclusives'
  end

  describe '#present_most_wished', described_method: :present_most_wished do
    it_behaves_like 'an exists in trends presentation', 'Most Wished'
  end

  describe '#present_trends', described_method: :present_trends do
    it_behaves_like 'a taxon values presentation', :trends

    context 'when a product is not on sale' do
      before do
        allow(described_instance).to receive(:build_taxon_values).and_return taxons
        allow(described_instance).to receive(:present_on_sale).and_return false
      end

      context 'when the product has the "On Sale" trend' do
        let(:taxons) { Array.wrap 'On Sale' }

        it { is_expected.not_to include('On Sale') }
      end

      context 'when the product does not have the "On Sale" trend' do
        let(:taxons) { [] }

        it { is_expected.not_to include('On Sale') }
      end
    end

    context 'when a product is on sale' do
      before do
        allow(described_instance).to receive(:build_taxon_values).and_return taxons
        allow(described_instance).to receive(:present_on_sale).and_return true
      end

      context 'with the on sale trend' do
        let(:taxons) { Array.wrap 'On Sale' }

        it { is_expected.to contain_exactly('On Sale') }
      end

      context 'without the on sale trend' do
        let(:taxons) { [] }

        it { is_expected.to include 'On Sale' }
      end
    end
  end

  describe '#present_master_or_variant_id', described_method: :present_master_or_variant_id do
    let(:variant) { create :master_variant }
    let(:product) { variant.product }

    it { is_expected.to eq variant.id }
  end

  describe '#present_monogrammable', described_method: :present_monogrammable do
    let(:monogrammable) { false }

    before do
      allow(product).to receive(:monogrammable?).and_return(monogrammable)
    end

    it 'calls monogrammable? method' do
      is_expected.to eq false

      expect(product).to have_received(:monogrammable?).once
    end

    context 'when monogrammable true' do
      let(:monogrammable) { true }

      it 'calls monogrammable? method' do
        is_expected.to eq true

        expect(product).to have_received(:monogrammable?).once
      end
    end
  end

  describe '#present_has_more_colors', described_method: :present_has_more_colors do
    context 'when the product has no variants' do
      it { is_expected.to be false }
    end

    context 'when the product has one variant with no colors' do
      let(:variant) { create :variant, :in_stock, :with_multiple_prices }
      let(:product) { variant.product }

      it { is_expected.to be false }
    end

    context 'when the product has one variant with one color' do
      let(:option_type) { create(:option_type, name: 'Color') }
      let(:option_values) do
        [
          create(:option_value, option_type: option_type)
        ]
      end
      let(:variant) { create :variant, :in_stock, :with_multiple_prices, option_values: option_values }
      let(:product) { variant.product }

      it { is_expected.to be false }
    end

    context 'when the product has one variant with two colors' do
      let(:option_type) { create(:option_type, name: 'Color') }
      let(:option_values) do
        [
          create(:option_value, option_type: option_type),
          create(:option_value, option_type: option_type)
        ]
      end
      let(:variant) { create :variant, :in_stock, :with_multiple_prices, option_values: option_values }
      let(:product) { variant.product }

      it { is_expected.to be true }
    end

    context 'when the product has one variant with two colors but the variant is not purchasable' do
      let(:option_type) { create(:option_type, name: 'Color') }
      let(:option_values) do
        [
          create(:option_value, option_type: option_type),
          create(:option_value, option_type: option_type)
        ]
      end
      let(:variant) do
        create :variant, :with_multiple_prices, :in_stock, option_values: option_values, vendor_prices: []
      end
      let(:product) { variant.product }

      it { is_expected.to be false }
    end

    context 'when the product has one variant with two colors but it is out of stock' do
      let(:option_type) { create(:option_type, name: 'Color') }
      let(:option_values) do
        [
          create(:option_value, option_type: option_type),
          create(:option_value, option_type: option_type)
        ]
      end
      let(:variant) { create :variant, option_values: option_values }
      let(:product) { variant.product }

      it { is_expected.to be false }
    end
  end

  describe '#present_slug', described_method: :present_slug do
    let(:product) { build_stubbed :product, slug: 'fake-product-slug' }

    it { is_expected.to eq 'fake-product-slug' }
  end

  describe 'present_is_product', described_method: :present_is_product do
    it { is_expected.to eq true }
  end

  describe 'present_upc', described_method: :present_upc do
    it_behaves_like 'a product property presentation', 'UPC Barcode'
  end

  describe 'present_google_product_category', described_method: :present_google_product_category do
    let(:product) { build_stubbed :product }
    let(:taxon) { instance_double Spree::Taxon, google_product_category: '5' }

    before do
      allow(product).to receive_messages(default_product_category_taxon: taxon)
    end

    it { is_expected.to eq '5' }
  end

  describe 'present_shipping_category', described_method: :present_shipping_category do
    it { is_expected.to be_nil }
  end

  describe 'present_margin', described_method: :present_margin do
    it_behaves_like 'a product property presentation', 'Margin'
  end

  describe 'present_estimated_shipping_cost', described_method: :present_estimated_shipping_cost do
    it { is_expected.to be_nil }
  end

  describe '#present_edits', described_method: :present_edits do
    it_behaves_like 'a taxon values presentation', :edit
  end

  describe '#present_variants_count', described_method: :present_variants_count do
    let(:variant) { create :variant, :in_stock, :with_multiple_prices }
    let(:product) { variant.product }

    it { is_expected.to eq 1 }
  end

  describe '#present_total_sales', described_method: :present_total_sales do
    let(:variant) { create :variant, :in_stock, :with_multiple_prices }
    let(:product) { variant.product }
    let(:incomplete_order) { create :order, line_items: [line_item1] }
    let(:complete_order) { create :order_ready_to_ship, line_items: [line_item2] }
    let(:line_item1) { create :line_item, variant: variant }
    let(:line_item2) { create :line_item, variant: variant }

    before do
      incomplete_order
      complete_order
    end

    it { is_expected.to eq 1 }
  end

  describe '#present_true_total_sales', described_method: :present_true_total_sales do
    let(:variant) { create :variant, :in_stock, :with_multiple_prices }
    let(:product) { variant.product }
    let(:incomplete_order) { create :order, line_items: [line_item1] }
    let(:complete_order) { create :order_ready_to_ship, line_items: [line_item2] }
    let(:line_item1) { create :line_item, variant: variant }
    let(:line_item2) { create :line_item, variant: variant, quantity: 2 }

    before do
      incomplete_order
      complete_order
    end

    it { is_expected.to eq 2 }
  end

  describe '#present_lifetime_total_sales', described_method: :present_lifetime_total_sales do
    let(:product) { create(:product) }
    let(:deleted_variant) { create :variant, :with_multiple_prices, product: product }
    let(:variant) { create :variant, :with_multiple_prices, product: product }
    let(:incomplete_order) { create :order, line_items: [line_item1] }
    let(:complete_order) { create :order_ready_to_ship, line_items: [line_item2, line_item3] }
    let(:line_item1) { create :line_item, variant: variant }
    let(:line_item2) { create :line_item, variant: variant, quantity: 2 }
    let(:line_item3) { create :line_item, variant: deleted_variant, quantity: 2 }

    before do
      incomplete_order
      complete_order
      deleted_variant.destroy
    end

    it { is_expected.to eq 4 }
  end

  describe 'present_pet_type', described_method: :present_pet_type do
    it_behaves_like 'a product property presentation', 'Pet Type'
  end

  describe 'present_main_category', described_method: :present_main_category do
    let(:product) { create :product, taxons: [main_category] }
    let(:main_category) { create :taxon, :main_category }

    it { is_expected.to eq 'Apparel' }
  end

  describe 'present_asin', described_method: :present_asin do
    it_behaves_like 'a product property presentation', 'ASIN'
  end

  describe 'present_holiday', described_method: :present_holiday do
    it_behaves_like 'a product property presentation', 'Holiday'
  end

  describe 'present_exclusive_definition', described_method: :present_exclusive_definition do
    it_behaves_like 'a product property presentation', 'Exclusive Definition'
  end

  describe '#present_exclude_price_scraping', described_method: :present_exclude_price_scraping do
    let(:product) { create :product, exclude_price_scraping: true }

    it { is_expected.to be true }
  end

  describe '#present_size_broken', described_method: :present_size_broken do
    let(:variant) { create :variant, :in_stock, :with_multiple_prices }
    let(:product) { variant.product }

    before do
      create_list(:variant, 2, :out_of_stock, :with_multiple_prices, product_id: product.id)
    end

    it { is_expected.to be true }
  end
end
