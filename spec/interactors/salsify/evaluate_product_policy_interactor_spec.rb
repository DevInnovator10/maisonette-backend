# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::EvaluateProductPolicyInteractor do
  describe '#call' do
    subject(:interactor) do
      described_class.call(
        row: row,
        product: product,
        variant: variant,
        pdp_variant_enabled: pdp_variant_enabled,
        rename_product_enabled: rename_product_enabled,
        import_product: import_product
      )
    end

    let(:variant) { create(:variant, product: create(:product)) }
    let(:product) { variant.product }
    let(:row) { { 'Item Name' => row_product_name } }
    let(:row_product_name) { 'Anna Dress, Blue' }
    let(:pdp_variant_enabled) { nil }
    let(:rename_product_enabled) { nil }
    let(:uuid) { 'UUID' }
    let(:import_product) { true }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
    end

    context 'when rename_product and pdp_variant are enabled' do
      let(:pdp_variant_enabled) { true }
      let(:rename_product_enabled) { true }
      let(:message) do
        'renamed_product and pdp_variant cannot be both enabled'
      end

      it 'fails' do
        expect(interactor).to be_a_failure
        expect(interactor.messages).to eq message
      end
    end

    context 'when is a product_rename' do
      let(:rename_product_enabled) { true }
      let(:row) { { 'Item Name' => row_product_name } }
      let(:row_product_name) { 'New product name' }

      let(:old_name) { 'Old product name' }
      let(:old_slug) { product.slug }
      let(:product) { create(:product, name: old_name) }

      before { product }

      it 'changes the product slug' do
        expect(product.slug).to eq 'old-product-name'

        interactor

        expect(interactor.product.slug).to be nil
      end
    end

    context 'when is a product migration' do
      let!(:product_by_name) { create(:product, name: 'Anna Dress') }
      let(:variant) { create(:variant, product: create(:product, name: product_name)) }
      let(:pdp_variant_enabled) { true }
      let(:product_name) { 'Anna Dress, Red' }

      before do
        allow(Salsify).to receive(:product_name).with(row).and_return('Anna Dress')
      end

      it 'assigns the found by name product to product context and new master_sku' do
        interactor

        expect(interactor.product).to eq product_by_name
        expect(interactor.old_product).to eq product

        expect(interactor.product_name).to eq 'Anna Dress'
        expect(interactor.master_sku).to eq uuid
      end

      context 'when import product is flase' do
        let(:import_product) { false }

        it 'does not generate a new master_sku' do
          interactor

          expect(interactor.product).to eq product_by_name
          expect(interactor.old_product).to eq product
          expect(interactor.product_name).to eq 'Anna Dress'
          expect(interactor.master_sku).to eq product_by_name.master.sku
        end
      end
    end

    context 'when is new_product with pdp_variant enabled' do
      let(:product) { nil }
      let(:pdp_variant_enabled) { true }

      before do
        allow(Salsify).to receive(:product_name).with(row).and_return('Anna Dress')
      end

      it 'assigns the name to the product_name context' do
        interactor

        expect(interactor.product).to be_nil
        expect(interactor.old_product).to be_nil
        expect(interactor.product_name).to eq 'Anna Dress'
        expect(interactor.master_sku).to eq uuid
      end

      context 'when import_product is false' do
        let!(:product_by_name) { create(:product, name: 'Anna Dress') }
        let(:import_product) { false }

        it 'assigns the name to the product_name context' do
          interactor

          expect(interactor.product).to eq product_by_name
          expect(interactor.old_product).to be_nil
          expect(interactor.product_name).to eq 'Anna Dress'
          expect(interactor.master_sku).to eq product_by_name.master.sku
        end
      end
    end

    context 'when is an already_migrated product with pdp_variant' do
      let!(:product_by_name) do
        maisonette_variant_group_attributes.product.tap do |p|
          p.update!(name: 'Anna Dress')
        end
      end
      let(:product) { product_by_name }
      let(:pdp_variant_enabled) { true }
      let(:maisonette_variant_group_attributes) { create(:maisonette_variant_group_attributes) }
      let(:variant) do
        product_by_name.variants.last
      end

      it 'assigns the product_name, master_sku context' do
        interactor

        expect(interactor.old_product).to be_nil
        expect(interactor.product_name).to eq 'Anna Dress'
        expect(interactor.master_sku).to eq product_by_name.master.sku
      end
    end

    context 'when is not part of any policy' do
      let(:pdp_variant_enabled) { false }
      let(:rename_product_enabled) { false }

      it 'does nothing' do
        expect(interactor).to be_a_success
        expect(interactor.product).to eq product
        expect(interactor.old_product).to be_nil
        expect(interactor.product_name).to be_nil
        expect(interactor.renamed_product).to be_nil
      end
    end
  end
end
