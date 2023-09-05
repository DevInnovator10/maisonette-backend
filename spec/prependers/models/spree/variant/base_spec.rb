# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Variant::Base, type: :model do
  let(:described_class) { Spree::Variant }

  it { is_expected.to delegate_method(:promotionable).to :product }
  it { is_expected.to delegate_method(:brand).to :product }
  it { is_expected.to delegate_method(:brand_description).to :product }
  it { is_expected.to delegate_method(:property).to :product }

  it { is_expected.to have_db_column :available_until }
  it { is_expected.to have_many(:stock_requests).dependent :nullify }
  it do
    is_expected.to have_many(:active_sale_prices).through(:prices).source(:sale_prices).class_name('Spree::SalePrice')
  end

  describe 'validations' do
    describe 'marketplace_sku' do
      let(:variant) { create(:variant, marketplace_sku: '12345|name|size|color') }
      let(:offer_setting1) { create :offer_settings, variant: variant }
      let(:offer_setting2) { create :offer_settings, variant: variant }

      context 'when the variant has multiple offer_settings' do
        before do
          offer_setting1
          offer_setting2
        end

        context 'when marketplace_sku is change on update' do
          it 'returns an error' do
            expect { variant.update!(marketplace_sku: 'ciao') }.to(
              raise_error(
                ActiveRecord::RecordInvalid,
                "Validation failed: Marketplace sku #{I18n.t('errors.spree.variant.marketplace_sku_change_not_allow')}"
              )
            )
          end

          context 'when skip_marketplace_sku_not_change_validation is true' do
            before do
              variant.skip_marketplace_sku_not_change_validation = true
            end

            it 'does not return an error' do
              expect { variant.update!(marketplace_sku: 'ciao') }.not_to raise_error
            end
          end
        end
      end

      context 'when the variant only has a single offer_settings' do
        before { offer_setting1 }

        it 'does not return an error' do
          expect { variant.update!(marketplace_sku: 'ciao') }.not_to raise_error
        end
      end
    end
  end

  # rubocop:disable RSpec/LetSetup
  describe '.active_sale_prices' do
    let(:variant) { create :variant, :with_multiple_prices }
    let(:price) { variant.prices.first }

    let!(:inactive) { create :sale_price, price: price, start_at: nil, end_at: nil, enabled: false }
    let!(:start_nil_end_nil) { create :sale_price, price: price, start_at: nil, end_at: nil, enabled: true }
    let!(:start_past_end_past) do
      create :sale_price, price: price, start_at: 2.days.ago, end_at: 1.day.ago, enabled: true
    end
    let!(:start_past_end_future) do
      create :sale_price, price: price, start_at: 2.days.ago, end_at: 1.day.from_now, enabled: true
    end
    let!(:start_future_end_future) do
      create :sale_price, price: price, start_at: 1.day.from_now, end_at: 2.days.from_now, enabled: true
    end

    it 'only returns current sale prices' do
      expect(variant.sale_prices.length).to eq 5
      expect(variant.active_sale_prices).to match_array [start_nil_end_nil, start_past_end_future]
    end
  end
  # rubocop:enable RSpec/LetSetup

  describe '#discontinued?' do
    subject { variant.discontinued? }

    let(:variant) { build_stubbed :variant, available_until: available_until, product: product }
    let(:product) { build_stubbed :product }

    before do
      allow(product).to receive_messages(discontinued?: product_discontinued?)
    end

    context 'when the product is not discontinued?' do
      let(:product_discontinued?) { false }

      context 'when available_until is nil' do
        let(:available_until) { nil }

        it { is_expected.to be false }
      end

      context 'when available_until is in the past' do
        let(:available_until) { 1.month.ago }

        it { is_expected.to be true }
      end

      context 'when available_until is in the future' do
        let(:available_until) { 1.month.from_now }

        it { is_expected.to be false }
      end
    end

    context 'when the product is discontinued?' do
      let(:product_discontinued?) { true }

      context 'when available_until is nil' do
        let(:available_until) { nil }

        it { is_expected.to be true }
      end

      context 'when available_until is in the past' do
        let(:available_until) { 1.month.ago }

        it { is_expected.to be true }
      end

      context 'when available_until is in the future' do
        let(:available_until) { 1.month.from_now }

        it { is_expected.to be true }
      end
    end
  end

  describe '#available?' do
    subject { variant.available? }

    let(:variant) { build_stubbed :variant }
    let(:product) { build_stubbed :product, available_on: available_on }

    before do
      allow(variant).to receive_messages(discontinued?: discontinued?, product: product)
    end

    context 'when discontinued' do
      let(:discontinued?) { true }

      context 'when available_on is nil' do
        let(:available_on) { nil }

        it { is_expected.to be false }
      end

      context 'when available_on is in the past' do
        let(:available_on) { 1.month.ago }

        it { is_expected.to be false }
      end

      context 'when available_on is in the future' do
        let(:available_on) { 1.month.from_now }

        it { is_expected.to be false }
      end
    end

    context 'when not discontinued' do
      let(:discontinued?) { false }

      context 'when available_on is nil' do
        let(:available_on) { nil }

        it { is_expected.to be false }
      end

      context 'when available_on is in the past' do
        let(:available_on) { 1.month.ago }

        it { is_expected.to be true }
      end

      context 'when available_on is in the future' do
        let(:available_on) { 1.month.from_now }

        it { is_expected.to be false }
      end
    end
  end

  describe '#wait_list' do
    let(:variant) { create :variant }
    let(:requests) { create_list :stock_request, 2, variant: variant }

    it 'is an active record relation' do
      expect(variant.wait_list).to be_a ActiveRecord::Relation
    end

    it 'only returns requested stock_requests' do
      allow(variant.stock_requests).to receive :requested

      variant.wait_list
      expect(variant.stock_requests).to have_received :requested
    end
  end

  describe '#queue_wait_list' do
    let(:variant) { create :variant }
    let(:null_relation) { instance_double ActiveRecord::NullRelation, update_all: true }

    before { allow(variant).to receive(:wait_list).and_return null_relation }

    it 'marks the wait list as queued' do
      variant.queue_wait_list
      expect(variant.wait_list).to have_received(:update_all).with(state: :queued)
    end
  end

  describe '#really_update_marketplace_sku!' do
    let(:variant) { create :variant, marketplace_sku: old_marketplace_sku }
    let(:old_marketplace_sku) { 'SKU1' }
    let(:old_sku) { variant.sku }

    let(:new_marketplace_sku) { 'SKU2' }

    it 'updates the marketplace_sku and sku' do
      expect(variant.sku).to eq old_sku
      expect(variant.marketplace_sku).to eq old_marketplace_sku

      variant.really_update_marketplace_sku!(new_marketplace_sku)

      expect(variant.sku).to eq old_sku
      expect(variant.marketplace_sku).to eq new_marketplace_sku
    end
  end
end
