# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Variant Group Attributes', type: :feature do
  stub_authorization!

  let(:index_page) { Admin::Maisonette::VariantGroupAttributes::IndexPage.new }
  let(:edit_page) { Admin::Maisonette::VariantGroupAttributes::EditPage.new }
  let(:variant_group_attributes) do
    create(
      :maisonette_variant_group_attributes,
      description: 'description',
      meta_description: 'meta description',
      meta_title: 'meta title',
      meta_keywords: 'meta keywords',
      sku: 'SKU-1'
    )
  end
  let(:product) { variant_group_attributes.product }
  let(:variant) { product.variants.first }
  let(:feature_enabled) { false }

  before do
    allow(Flipper).to receive(:enabled?).and_return(feature_enabled)
  end

  context 'when features is enabled' do
    context 'when user visits the variant group attributes index page' do
      let(:feature_enabled) { true }

      it 'can see the list of the variant group attributes' do # rubocop:disable RSpec/MultipleExpectations
        index_page.load(product_slug: product.slug)
        expect(index_page).to be_displayed

        expect(index_page).to have_content(variant_group_attributes.description)
        expect(index_page).to have_content(variant_group_attributes.meta_description)
        expect(index_page).to have_content(variant_group_attributes.meta_title)
        expect(index_page).to have_content(variant_group_attributes.meta_keywords)
        expect(index_page).to have_content(variant_group_attributes.sku)
      end
    end

    context 'when user visits the variant group attributes edit page' do
      let(:feature_enabled) { true }

      before do
        edit_page.load(product_slug: product.slug, variant_group_attributes_id: variant_group_attributes.id)
      end

      it 'can update an variant group attributes record' do
        expect(edit_page).to be_displayed

        form = edit_page.form

        expect(form.option_value_select.disabled?).to eq true

        form.description.set 'Edited'
        form.meta_description.set 'Edited'
        form.meta_title.set 'Edited'
        form.meta_keywords.set 'Edited'
        form.sku.set 'Edited'

        click_on('Update')

        index_page.load(product_slug: product.slug)

        expect(index_page).to be_displayed

        expect(index_page).to have_content('Edited')
      end
    end

    context 'when maisonette_sale feature is disabled' do
      let(:feature_enabled) { false }

      it 'displays a not allowed message' do
        index_page.load(product_slug: product.slug)

        expect(index_page).to have_content('Access not allowed')
      end
    end
  end
end
