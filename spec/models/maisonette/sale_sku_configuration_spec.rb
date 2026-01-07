# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::SaleSkuConfiguration, type: :model do
  describe 'associations' do
    it {
      is_expected.to belong_to(:offer_settings).class_name('Spree::OfferSettings').inverse_of(:sale_sku_configurations)
    }
    it { is_expected.to belong_to(:sale).class_name('Maisonette::Sale') }
    it { is_expected.to belong_to(:sale_price).class_name('Spree::SalePrice').optional }
    it { is_expected.to belong_to(:created_by).class_name('Spree::User') }
    it { is_expected.to belong_to(:updated_by).class_name('Spree::User') }
  end

  describe 'offer settings association' do
    it 'returns a discarded offer settings' do
      offer_settings = create :offer_settings, discarded_at: 1.day.ago
      sale_sku_configuration = create :sale_sku_configuration, offer_settings: offer_settings
      expect(sale_sku_configuration.reload.offer_settings).to eq offer_settings
    end
  end

  describe 'validations' do
    it { is_expected.to validate_numericality_of(:percent_off).is_greater_than_or_equal_to(0.01).allow_nil }
    it { is_expected.to validate_numericality_of(:percent_off).is_less_than_or_equal_to(0.99).allow_nil }

    context 'when static cost price is set without a static sale price' do
      it { expect(build(:sale_sku_configuration, static_cost_price: 10, static_sale_price: nil)).to be_invalid }

      it 'has errors on static cost price' do
        sale_sku_configuration = build(:sale_sku_configuration, static_cost_price: 10, static_sale_price: nil)
        sale_sku_configuration.validate

        expect(sale_sku_configuration.errors[:static_cost_price]).to include('must have a static sale price')
      end
    end
  end

  describe 'callbacks' do
    describe '#add_created_by' do
      it 'updates created by field with updated by' do
        sale_sku_configuration = create(:sale_sku_configuration, created_by: nil)

        expect(sale_sku_configuration.created_by).to eq(sale_sku_configuration.updated_by)
      end
    end
  end

  describe 'callbacks' do
    describe '#disable_sale_price' do
      it 'disables sale price when destroyed' do
        sale_price = create(:sale_price, enabled: true)
        sale_sku = create(:sale_sku_configuration, sale_price: sale_price)

        sale_sku.destroy

        expect(sale_price).not_to be_enabled
      end
    end

    describe '#add_product_to_taxon' do
      context 'when sale has a taxon' do
        let(:taxon) { create(:taxon) }
        let(:sale) { create(:sale, taxon: taxon) }
        let(:sale_sku_configuration) { build(:sale_sku_configuration, sale: sale) }
        let(:product) { sale_sku_configuration.offer_settings.variant.product }

        it 'adds the sale taxon to the sale_sku_configuration product' do
          sale_sku_configuration.save
          expect(product.reload.taxons).to include(taxon)
        end
      end

      context 'when sale does not have a taxon' do
        let(:sale) { create(:sale) }
        let(:sale_sku_configuration) { build(:sale_sku_configuration, sale: sale) }
        let(:product) { sale_sku_configuration.offer_settings.variant.product }

        it 'captures the exception and send it to sentry' do
          allow(Sentry).to receive(:capture_exception_with_message)

          sale_sku_configuration.save
          expect(Sentry).to have_received(:capture_exception_with_message).with(
            an_instance_of(NoMethodError),
            message: 'Failure on adding product to taxon',
            extra: { sale_sku_configuration_id: sale_sku_configuration.id, product_id: product.id, taxon: nil }
          )
        end
      end
    end

    describe '#remove_product_from_taxon' do
      let(:product) { create(:product) }
      let(:variant) { create(:variant, product: product) }
      let(:offer_settings) { create(:offer_settings, variant: variant) }

      let(:taxon) { create(:taxon) }
      let(:sale) { create(:sale, taxon: taxon) }
      let(:sale_sku_configuration) { create(:sale_sku_configuration, sale: sale, offer_settings: offer_settings) }

      context "when the sale doesn't contain sale_sku_configurations pointing to the same product anymore" do
        it 'removes the sale taxon from the sale_sku_configuration product' do
          sale_sku_configuration.destroy
          expect(product.reload.taxons).not_to include(taxon)
        end
      end

      context 'when the sale still contains sale_sku_configurations pointing to the same product' do
        before do
          second_variant = create(:variant, product: product)
          second_offer_settings = create(:offer_settings, variant: second_variant)
          create(:sale_sku_configuration, sale: sale, offer_settings: second_offer_settings)
        end

        it "doesn't remove the sale taxon from the sale_sku_configuration product" do
          sale_sku_configuration.destroy
          expect(product.reload.taxons).to include(taxon)
        end
      end
    end
  end

  describe '#config_for' do
    subject(:described_method) { sale_sku_configuration.config_for(attribute) }

    let(:sale) { create(:sale, final_sale: true) }
    let(:sale_sku_configuration) { create(:sale_sku_configuration, sale: sale, final_sale: final_sale) }
    let(:final_sale) { false }
    let(:attribute) { :final_sale }

    context 'when sale_sku_configuration#final_sale is not nil' do
      it 'returns the local configuration' do
        is_expected.to be(false)
      end
    end

    context 'when sale_sku_configuration#final_sale is nil' do
      let(:final_sale) { nil }

      it 'returns the default configuration from the main sale' do
        is_expected.to be(true)
      end
    end

    context 'when the passed attribute is not valid' do
      let(:attribute) { :not_existing }

      it 'throws a NoMethodError exception' do
        expect { described_method }.to raise_exception(NoMethodError)
      end
    end
  end

  describe '#vendor_liability' do
    let(:sale) { create(:sale, maisonette_liability: 75) }
    let(:sale_sku_configuration) { create(:sale_sku_configuration, sale: sale) }

    context 'when sale_sku_configuration#maisonette_liability is not nil' do
      it 'returns the vendor liability percentage' do
        sale_sku_configuration.maisonette_liability = 80
        expect(sale_sku_configuration.vendor_liability).to eq(20)
      end
    end

    context 'when sale_sku_configuration#maisonette_liability is nil' do
      it 'returns the vendor liability percentage' do
        expect(sale_sku_configuration.vendor_liability).to eq(25)
      end
    end
  end

  describe '#maisonette_liability_amount' do
    subject(:described_method) { sale_sku_configuration.maisonette_liability_amount }

    let(:sale_price) {}
    let(:sale_sku_configuration) do
      create(:sale_sku_configuration, sale_price: sale_price, maisonette_liability: 20)
    end

    context 'when sale price is not nil' do
      let(:price) { create(:price, original_price: 100) }
      let(:sale_price) do
        create(:sale_price, value: 0.1, price: price, enabled: true,
                            calculator: Spree::Calculator::PercentOffSalePriceCalculator.new)
      end

      it 'computes the maisonette liability amount' do
        is_expected.to eq 2
      end

      context 'with a deleted price' do
        before do
          price.discard
          sale_price.reload
        end

        it 'raises no errors' do
          expect { described_method }.not_to raise_error
        end
      end
    end

    context 'when sale price is not nil' do
      it { is_expected.to be_nil }
    end
  end

  describe '#vendor_liability_amount' do
    subject(:described_method) { sale_sku_configuration.vendor_liability_amount }

    let(:sale_price) {}
    let(:sale_sku_configuration) do
      create(:sale_sku_configuration, sale_price: sale_price, maisonette_liability: 20)
    end

    context 'when sale price is not nil' do
      let(:price) { create(:price, original_price: 100) }
      let(:sale_price) do
        create(:sale_price, value: 0.1, price: price, enabled: true,
                            calculator: Spree::Calculator::PercentOffSalePriceCalculator.new)
      end

      it 'computes the vendor liability amount' do
        is_expected.to eq 8
      end

      context 'with a deleted price' do
        before do
          price.discard
          sale_price.reload
        end

        it 'raises no errors' do
          expect { described_method }.not_to raise_error
        end
      end
    end

    context 'when sale price is not nil' do
      it { is_expected.to be_nil }
    end
  end

  describe 'Scopes' do
    describe '.active_on', freeze_time: true do
      let(:permanent_sale) do
        create :sale, start_date: Time.zone.yesterday.beginning_of_day, end_date: nil, permanent: true
      end

      let(:sale_sku_with_default_configuration) { create :sale_sku_configuration, sale: permanent_sale }
      let(:permanent_sale_sku_active_from_tomorrow) do
        create :sale_sku_configuration, sale: permanent_sale, start_date: Time.zone.tomorrow.beginning_of_day,
                                        end_date: nil
      end
      let(:sale_sku_finished_yesterday) do
        create :sale_sku_configuration, sale: permanent_sale, start_date: nil, end_date: Time.zone.yesterday.end_of_day
      end
      let(:today_sale_sku) do
        create :sale_sku_configuration, sale: permanent_sale, start_date: Time.zone.today.beginning_of_day,
                                        end_date: Time.zone.today.end_of_day
      end

      before do
        sale_sku_with_default_configuration
        permanent_sale_sku_active_from_tomorrow
        sale_sku_finished_yesterday
        today_sale_sku
      end

      it 'returns the active sale_sku_configurations for specific date' do
        expect(described_class.active_on(Time.current).ids).to(
          contain_exactly(sale_sku_with_default_configuration.id, today_sale_sku.id)
        )
        expect(described_class.active_on((Time.current - 1.day)).ids).to(
          contain_exactly(sale_sku_with_default_configuration.id, sale_sku_finished_yesterday.id)
        )
        expect(described_class.active_on(Time.current + 1.day).ids).to(
          contain_exactly(sale_sku_with_default_configuration.id, permanent_sale_sku_active_from_tomorrow.id)
        )
      end

      context 'when the date is a String' do
        it 'returns the active sale_sku_configurations for specific date' do
          expect(described_class.active_on(Time.current.to_s).ids).to(
            contain_exactly(sale_sku_with_default_configuration.id, today_sale_sku.id)
          )
        end
      end
    end

    describe '.config_for_eq' do
      let(:sale) { create :sale, percent_off: 0.2 }

      let(:sale_sku_with_default_configuration) { create :sale_sku_configuration, sale: sale }
      let(:sale_sku_with_custom_configuration) { create :sale_sku_configuration, sale: sale, percent_off: 0.3 }
      let(:sale_sku_with_custom_configuration_equal_to_default) do
        create :sale_sku_configuration, sale: sale, percent_off: 0.2
      end

      before do
        sale_sku_with_default_configuration
        sale_sku_with_custom_configuration
        sale_sku_with_custom_configuration_equal_to_default
      end

      it 'returns the active sale_sku_configurations for specific date' do
        expect(described_class.config_for_eq(:percent_off, 0.2).ids).to(
          contain_exactly(sale_sku_with_default_configuration.id,
                          sale_sku_with_custom_configuration_equal_to_default.id)
        )
        expect(described_class.config_for_eq(:percent_off, 0.3).ids).to(
          contain_exactly(sale_sku_with_custom_configuration.id)
        )
      end
    end

    describe '.in_stock' do
      let(:product) { create(:product_in_stock) }
      let(:stock_location) { product.master.stock_items.first.stock_location }
      let(:vendor) { create(:vendor, stock_location: stock_location) }
      let(:offer_settings) { create :offer_settings, variant: product.master, vendor: vendor }

      let(:sale_sku_in_stock) { create :sale_sku_configuration, offer_settings: offer_settings }
      let(:sale_sku_out_of_stock) { create :sale_sku_configuration }

      before do
        sale_sku_in_stock
        sale_sku_out_of_stock
      end

      it 'returns the in_stock sale_sku_configurations' do
        expect(described_class.all.ids).to contain_exactly(sale_sku_in_stock.id, sale_sku_out_of_stock.id)
        expect(described_class.in_stock.ids).to contain_exactly(sale_sku_in_stock.id)
      end
    end
  end
end
