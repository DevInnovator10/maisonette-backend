# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Syndication::Concerns::AlgoliaProductIndex, type: :model do
    let(:described_class) { Syndication::Product }

  shared_examples 'a trends boolean' do |trend_name|
    describe '#value' do
      subject { |example| syndication_product.public_send example.metadata[:described_method] }

      let(:syndication_product) { create :syndication_product, :for_product, trends: trends }

      context 'when the product has the trend best_sellers_this_season' do
        let(:trends) { trend_name }

        it { is_expected.to eq true }
      end

      context 'when the product does not have the trend best_sellers_this_season' do
        let(:trends) { 'On Sale' }

        it { is_expected.to eq false }
      end
    end

    describe '#will_save_change_to_?' do
      subject do |example|
        syndication_product.public_send "will_save_change_to_#{example.metadata[:described_method]}?"
      end

      let(:syndication_product) { create :syndication_product, :for_product }

      context 'when the product trends change' do
        before do
          syndication_product.trends = 'A new trend!'
        end

        it { is_expected.to eq true }
      end

      context 'when the product trends does not change' do
        before do
          syndication_product.trends = syndication_product.trends
        end

        it { is_expected.to eq false }
      end
    end
  end

  describe 'attributes' do
    let(:attributes) do
      described_class::ALGOLIA_PRODUCT_ATTRIBUTES + [:percent_off, :on_sale, :edits]
    end

    it 'only updates the record if the attributes change' do
      attributes.each do |attribute|
        expect(described_class.new).to respond_to "will_save_change_to_#{attribute}?"
      end
    end
  end

  describe '.trigger_algolia_worker' do
    subject(:trigger_algolia_worker) { described_class.trigger_algolia_worker(syndication_product, remove_boolean) }

    let(:syndication_product) { instance_double(described_class, master_or_variant_id: 1001, is_product: is_product) }
    let(:remove_boolean) { true }

    before do
      allow(Algolia::SyncProductWorker).to receive(:perform_async)
      trigger_algolia_worker
    end

    context 'when the record is a product' do
      let(:is_product) { true }

      it 'calls Algolia::SyncProductWorker with the record algolia id and remove boolean' do
        expect(Algolia::SyncProductWorker).to(
          have_received(:perform_async).with(syndication_product.master_or_variant_id,
                                             remove_boolean)
        )
      end
    end

    context 'when the record is a variant' do
      let(:is_product) { false }

      it 'does not call Algolia::SyncProductWorker' do
        expect(Algolia::SyncProductWorker).not_to have_received(:perform_async)
      end
    end
  end

  describe '#variants' do
    subject(:variants) { syndication_product.variants }

    let(:syndication_product) { create :syndication_product, :for_product }
    let(:syndication_product_variant1) do
      create :syndication_product, :for_variant,
             manufacturer_id: syndication_product.manufacturer_id
    end
    let(:syndication_product_variant2) do
      create :syndication_product, :for_variant,
             manufacturer_id: syndication_product.manufacturer_id
    end
    let(:variant_hash1) do
      {
        'maisonette_sku' => syndication_product_variant1.maisonette_sku,
        'boutique' => syndication_product_variant1.boutique,
        'maisonette_retail' => syndication_product_variant1.maisonette_retail,
        'maisonette_sale' => syndication_product_variant1.maisonette_sale,
        'size' => syndication_product_variant1.size,
        'age_range' => syndication_product_variant1.age_range,
        'clothing_sizes' => syndication_product_variant1.clothing_sizes,
        'shoe_sizes' => syndication_product_variant1.shoe_sizes
      }
    end
    let(:variant_hash2) do
      {
        'maisonette_sku' => syndication_product_variant2.maisonette_sku,
        'boutique' => syndication_product_variant2.boutique,
        'maisonette_retail' => syndication_product_variant2.maisonette_retail,
        'maisonette_sale' => syndication_product_variant2.maisonette_sale,
        'size' => syndication_product_variant2.size,
        'age_range' => syndication_product_variant2.age_range,
        'clothing_sizes' => syndication_product_variant2.clothing_sizes,
        'shoe_sizes' => syndication_product_variant2.shoe_sizes
      }
    end

    before do
      syndication_product
      syndication_product_variant1
      syndication_product_variant2
    end

    it 'returns a array of hashes of the variants associated with the product' do
      expect(variants).to match_array([variant_hash1, variant_hash2])
    end
  end

  describe '#will_save_change_to_variants?' do
    subject(:will_save_change_to_variants?) { syndication_product.will_save_change_to_variants? }

    let(:syndication_product) { create :syndication_product, :for_product }
    let(:syndication_product_variant1) do
      create :syndication_product, :for_variant,
             manufacturer_id: syndication_product.manufacturer_id
    end

    before do
      syndication_product
      syndication_product_variant1.update(algolia_attributes_updated_at: variant_algolia_attributes_updated_at)
    end

    context 'when the variant algolia_attributes_updated_at is greater than the product updated_at' do
      let(:variant_algolia_attributes_updated_at) { syndication_product.updated_at + 1.hour }

      it 'returns true' do
        expect(will_save_change_to_variants?).to eq true
      end
    end

    context 'when the variant algolia_attributes_updated_at is less than the product updated_at' do
      let(:variant_algolia_attributes_updated_at) { syndication_product.updated_at - 1.hour }

      it 'returns false' do
        expect(will_save_change_to_variants?).to eq false
      end
    end
  end

  describe '#categories' do
    subject(:categories) { syndication_product.categories }

    let(:syndication_product) { create :syndication_product, :for_product, category: product_category }
    let(:product_category) do
      ['Dresses', 'Girl > Dresses', 'Kids', 'Kids > Girls Clothing', 'Kids > Girls Clothing > Dresses']
    end
    let(:category_facet_hashes) do
      { lvl0: %w[Dresses Kids],
        lvl1: ['Girl > Dresses', 'Kids > Girls Clothing'],
        lvl2: ['Kids > Girls Clothing > Dresses'] }
    end

    it 'returns the category facet hash' do
      expect(categories).to match_array category_facet_hashes
    end
  end

  describe '#categories_slug' do
    subject(:categories) { syndication_product.categories_slug }

    let(:syndication_product) { create :syndication_product, :for_product, category: product_category }
    let(:product_category) do
      ['Dresses', 'Girl > Dresses', 'Kids', 'Kids > Girls Clothing', 'Kids > Girls Clothing > Dresses']
    end
    let(:category_facet_slug_hashes) do
      { lvl0: %w[dresses kids],
        lvl1: ['girl > dresses', 'kids > girls-clothing'],
        lvl2: ['kids > girls-clothing > dresses'] }
    end
    let(:category_taxonomy) { create(:taxonomy, :category) }

    before do
      create(:taxon, name: 'Dresses', taxonomy: category_taxonomy)
      create(:taxon, name: 'Kids', taxonomy: category_taxonomy)
      create(:taxon, name: 'Girls Clothing', taxonomy: category_taxonomy)
      create(:taxon, name: 'Girl', taxonomy: category_taxonomy)
    end

    it 'returns the category facet slug hash' do
      expect(categories).to match_array category_facet_slug_hashes
    end
  end

  describe '#categories' do
    subject(:categories) { syndication_product.categories }

    let(:syndication_product) { create :syndication_product, :for_product, category: product_category }
    let(:product_category) do
      ['Dresses', 'Girl > Dresses', 'Kids', 'Kids > Girls Clothing', 'Kids > Girls Clothing > Dresses']
    end
    let(:category_facet_hashes) do
      { lvl0: %w[Dresses Kids],
        lvl1: ['Girl > Dresses', 'Kids > Girls Clothing'],
        lvl2: ['Kids > Girls Clothing > Dresses'] }
    end

    it 'returns the category facet hash' do
      expect(categories).to match_array category_facet_hashes
    end
  end

  describe '#will_save_change_to_categories?' do
    subject(:will_save_change_to_categories?) { syndication_product.will_save_change_to_categories? }

    let(:syndication_product) { create :syndication_product, :for_product }

    context 'when the product category changes' do
      before do
        syndication_product.category = 'New category'
      end

      it 'returns true' do
        expect(will_save_change_to_categories?).to eq true
      end
    end

    context 'when the product category does not change' do
      before do
        syndication_product.category = syndication_product.category
      end

      it 'returns false' do
        expect(will_save_change_to_categories?).to eq false
      end
    end
  end

  describe '#available_on_to_i' do
    subject(:available_on_to_i) { syndication_product.available_on_to_i }

    let(:syndication_product) { create :syndication_product, :for_product }

    it 'returns the available on as an integer' do
      expect(available_on_to_i).to eq DateTime.parse(syndication_product.available_on).to_i
    end
  end

  describe '#will_save_change_to_available_on_to_i?' do
    subject(:will_save_change_to_available_on_to_i?) { syndication_product.will_save_change_to_available_on_to_i? }

    let(:syndication_product) { create :syndication_product, :for_product }

    context 'when the product available on' do
      before do
        syndication_product.available_on = Time.current
      end

      it 'returns true' do
        expect(will_save_change_to_available_on_to_i?).to eq true
      end
    end

    context 'when the product available on does not change' do
      before do
        syndication_product.available_on = syndication_product.available_on
      end

      it 'returns false' do
        expect(will_save_change_to_available_on_to_i?).to eq false
      end
    end
  end

  describe '#low_stock' do
    subject(:low_stock) { syndication_product.low_stock }

    let(:syndication_product) { create :syndication_product, :for_product, inventory_status: inventory_status }

    context 'when the inventory status is low stock' do
      let(:inventory_status) { I18n.t('total_on_hand.statuses.low_inventory') }

      it 'returns true' do
        expect(low_stock).to eq true
      end
    end

    context 'when the inventory status is no low stock' do
      let(:inventory_status) { 'In Stock' }

      it 'returns false' do
        expect(low_stock).to eq false
      end
    end
  end

  describe '#will_save_change_to_low_stock?' do
    subject(:will_save_change_to_low_stock?) { syndication_product.will_save_change_to_low_stock? }

    let(:syndication_product) { create :syndication_product, :for_product }

    context 'when the product inventory_status changes' do
      before do
        syndication_product.inventory_status = 'Low Stock'
      end

      it 'returns true' do
        expect(will_save_change_to_low_stock?).to eq true
      end
    end

    context 'when the product inventory_status does not change' do
      before do
        syndication_product.inventory_status = syndication_product.inventory_status
      end

      it 'returns false' do
        expect(will_save_change_to_low_stock?).to eq false
      end
    end
  end

  describe '#title' do
    subject(:title) { syndication_product.title }

    let(:syndication_product) { create :syndication_product, :for_product }

    it 'returns the product_name' do
      expect(title).to eq syndication_product.product_name
    end
  end

  describe '#will_save_change_to_title?' do
    subject(:will_save_change_to_title?) { syndication_product.will_save_change_to_title? }

    let(:syndication_product) { create :syndication_product, :for_product }

    context 'when the product name changes' do
      before do
        syndication_product.product_name = 'Not Anna Dress'
      end

      it 'returns true' do
        expect(will_save_change_to_title?).to eq true
      end
    end

    context 'when the product name does not change' do
      before do
        syndication_product.product_name = syndication_product.product_name
      end

      it 'returns false' do
        expect(will_save_change_to_title?).to eq false
      end
    end
  end

  describe '#text' do
    subject(:text) { syndication_product.text }

    let(:syndication_product) { create :syndication_product, :for_product }

    it 'returns the product description' do
      expect(text).to eq syndication_product.vendor_sku_description
    end
  end

  describe '#will_save_change_to_text?' do
    subject(:will_save_change_to_text?) { syndication_product.will_save_change_to_text? }

    let(:syndication_product) { create :syndication_product, :for_product }

    context 'when the product description changes' do
      before do
        syndication_product.vendor_sku_description = 'The worst product'
      end

      it 'returns true' do
        expect(will_save_change_to_text?).to eq true
      end
    end

    context 'when the product description does not change' do
      before do
        syndication_product.vendor_sku_description = syndication_product.vendor_sku_description
      end

      it 'returns false' do
        expect(will_save_change_to_text?).to eq false
      end
    end
  end

  describe '#edits' do
    subject(:edits) { syndication_product.edits }

    let(:syndication_product) { create :syndication_product, :for_product }
    let(:edits_taxonomy) { create(:taxonomy, :edit) }

    before do
      create(:taxon, name: 'Just In', taxonomy: edits_taxonomy)
      create(:taxon, name: 'REGISTRY MOCK UP', taxonomy: edits_taxonomy)
      create(:taxon, name: 'The Gear: On A Budget', taxonomy: edits_taxonomy)
    end

    it 'returns an array of edits permalinks' do
      expect(edits).to eq %w[just-in registry-mock-up the-gear-on-a-budget]
    end
  end

  describe '#trends_slug' do
    subject(:trends_slug) { syndication_product.trends_slug }

    let(:syndication_product) { create :syndication_product, :for_product, trends: ['On Sale', 'Just In'] }
    let(:trends_taxonomy) { create(:taxonomy, :trends) }

    before do
      create(:taxon, name: 'On Sale', taxonomy: trends_taxonomy)
      create(:taxon, name: 'Just In', taxonomy: trends_taxonomy)
    end

    it 'returns the taxon slug' do
      expect(trends_slug).to eq %w[on-sale just-in]
    end
  end

  describe '#brand_slug' do
    subject(:trends_slug) { syndication_product.brand_slug }

    let(:syndication_product) { create :syndication_product, :for_product, brand: 'This Brand' }

    before { create(:taxon, name: 'This Brand') }

    it 'returns the taxon slug' do
      expect(trends_slug).to eq 'this-brand'
    end
  end

  describe '#private_label_brand' do
    subject(:private_label_brand) { syndication_product.private_label_brand }

    context 'when the product brand is Maison Me' do
      let(:syndication_product) { create :syndication_product, :for_product, brand: 'Maison Me' }

      before { create(:taxon, name: 'Maison Me') }

      it 'returns the true' do
        expect(private_label_brand).to eq true
      end
    end

    context 'when the product brand does not PL Brands' do
      let(:syndication_product) { create :syndication_product, :for_product, brand: 'This Brand' }

      before { create(:taxon, name: 'This Brand') }

      it 'returns the false' do
        expect(private_label_brand).to eq false
      end
    end

    context 'when the product brand is empty' do
      let(:syndication_product) { create :syndication_product, :for_product }

      it 'returns the false' do
        expect(private_label_brand).to eq false
      end
    end
  end

  describe '#season_year' do
    subject(:season_year) { syndication_product.season_year }

    context 'when the product season is SS23' do
      let(:syndication_product) { create :syndication_product, :for_product, season: 'SS23' }

      it 'returns season name SS23' do
        expect(season_year).to eq 'SS23'
      end
    end

    context 'when the product season is empty' do
      let(:syndication_product) { create :syndication_product, :for_product }

      it { expect(season_year).to eq nil }
    end
  end

  describe '#core' do
    subject(:core) { syndication_product.core }

    context 'when the product season is CORE' do
      let(:syndication_product) { create :syndication_product, :for_product, season: 'CORE' }

      it 'returns core' do
        expect(core).to eq 'Core'
      end
    end

    context 'when the product season is SS23' do
      let(:syndication_product) { create :syndication_product, :for_product, season: 'SS23' }

      it 'returns non-core' do
        expect(core).to eq 'Non-Core'
      end
    end
  end

  describe '#holiday' do
    subject(:holiday) { syndication_product.holiday }

    context 'when the product holiday is Christmas' do
      let(:syndication_product) { create :syndication_product, :for_product, holiday: 'Christmas' }

      it 'returns Christmas' do
        expect(holiday).to eq 'Christmas'
      end
    end
  end

  describe '#exclusive_type' do
    subject(:exclusive_type) { syndication_product.exclusive_type }

    context 'when the product exclusive definition is Exclusive' do
      let(:syndication_product) { create :syndication_product, :for_product, exclusive_definition: 'Exclusive' }

      it 'returns Exclusive' do
        expect(exclusive_type).to eq 'Exclusive'
      end
    end
  end

  describe '#slug' do
    subject(:slug) { syndication_product.slug }

    context 'when the product slug is product_slug' do
      let(:syndication_product) { create :syndication_product, :for_product, slug: 'product_slug' }

      it 'returns product_slug' do
        expect(slug).to eq 'product_slug'
      end
    end
  end

  describe '#best_sellers_today', described_method: :best_sellers_today do
    it_behaves_like 'a trends boolean', Spree::Taxon::SELLING_FAST_TODAY
  end

  describe '#best_sellers_this_week', described_method: :best_sellers_this_week do
    it_behaves_like 'a trends boolean', Spree::Taxon::SELLING_FAST_THIS_WEEK
  end

  describe '#best_sellers_this_month', described_method: :best_sellers_this_month do
    it_behaves_like 'a trends boolean', Spree::Taxon::SELLING_FAST
  end

  describe '#best_sellers_this_month', described_method: :best_sellers_this_month do
    it_behaves_like 'a trends boolean', Spree::Taxon::SELLING_FAST
  end

  describe '#best_sellers_this_season', described_method: :best_sellers_this_season do
    it_behaves_like 'a trends boolean', Spree::Taxon::BEST_SELLERS_THIS_SEASON
  end

  describe '#best_sellers_this_year', described_method: :best_sellers_this_year do
    it_behaves_like 'a trends boolean', Spree::Taxon::BEST_SELLERS
  end

  describe '#best_sellers_all_time', described_method: :best_sellers_all_time do
    it_behaves_like 'a trends boolean', Spree::Taxon::ALL_TIME_BEST_SELLERS
  end

  describe '#new_in_today', described_method: :new_in_today do
    it_behaves_like 'a trends boolean', Spree::Taxon::NEW_TODAY
  end

  describe '#new_in_this_week', described_method: :new_in_this_week do
    it_behaves_like 'a trends boolean', Spree::Taxon::NEW_THIS_WEEK
  end

  describe '#new_in_this_month', described_method: :new_in_this_month do
    it_behaves_like 'a trends boolean', Spree::Taxon::JUST_IN
  end

  describe '#new_in_six_weeks', described_method: :new_in_six_weeks do
    it_behaves_like 'a trends boolean', Spree::Taxon::NEW_IN_SIX_WEEKS
  end
end
