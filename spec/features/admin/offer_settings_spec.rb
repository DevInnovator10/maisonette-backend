# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Offer Settings', type: :feature do
  stub_authorization!

  let(:index_page) { Admin::OfferSettings::IndexPage.new }
  let(:new_page) { Admin::OfferSettings::NewPage.new }
  let(:edit_page) { Admin::OfferSettings::EditPage.new }

  context 'when user visits the offer settings index page' do
    let(:variant) { create :variant, :with_multiple_prices }
    let(:product) { variant.product }
    let(:vendors) { variant.vendors }
    let(:other_variant) { create :variant, :with_multiple_prices }
    let(:other_vendors) { other_variant.vendors }

    before do
      vendors.each do |vendor|
        create :offer_settings, variant: variant, vendor: vendor
      end

      other_vendors.each do |other_vendor|
        create :offer_settings, variant: other_variant, vendor: other_vendor
      end
    end

    it 'can see the list of the product offer settings' do
      index_page.load(product_slug: product.slug)
      expect(index_page).to be_displayed

      expect(index_page).to have_content(variant.descriptive_name)
      vendors.each do |vendor|
        expect(index_page).to have_content(vendor.name)
      end

      expect(index_page).not_to have_content(other_variant.descriptive_name)
      other_vendors.each do |other_vendor|
        expect(index_page).not_to have_content(other_vendor.name)
      end
    end
  end

  context 'when user visits the offer settings new page', :js do
    let(:variant) { create :variant, :with_multiple_prices }
    let(:product) { variant.product }
    let(:vendor) { variant.vendors.first }

    it 'can create a new offer settings record' do
      new_page.load(product_slug: product.slug)
      expect(new_page).to be_displayed

      form = new_page.form

      form.variant_select.select variant.descriptive_name
      form.vendor_select.select vendor.name
      form.vendor_sku.set 'A-DRESS-01'
      form.maisonette_sku.set 'LIND10'

      form.monogram_price_number_field.set '2.34'
      form.monogram_cost_price_number_field.set '1.23'
      form.monogram_lead_time_number_field.set '5'
      form.monogram_max_text_length_number_field.set '10'

      click_on('Create')

      index_page.load(product_slug: product.slug)

      expect(index_page).to be_displayed

      expect(index_page).to have_content(variant.descriptive_name)
      expect(index_page).to have_content(vendor.name)
    end
  end

  context 'when user visits the offer settings edit page' do
    let(:offer_settings) { create :offer_settings }
    let(:variant) { offer_settings.variant }
    let(:vendor) { offer_settings.vendor }
    let(:product) { variant.product }

    before { edit_page.load(product_slug: product.slug, offer_settings_id: offer_settings.id) }

    it 'can update an offer settings record' do
      expect(edit_page).to be_displayed

      form = edit_page.form

      form.variant_select.select variant.descriptive_name
      form.vendor_select.select vendor.name

      form.monogram_price_number_field.set '2.34'
      form.monogram_cost_price_number_field.set '1.23'
      form.monogram_lead_time_number_field.set '5'
      form.monogram_max_text_length_number_field.set '10'

      click_on('Update')

      index_page.load(product_slug: product.slug)

      expect(index_page).to be_displayed

      expect(index_page).to have_content(variant.descriptive_name)
      expect(index_page).to have_content(vendor.name)
    end

    context 'when logistics customizations do not exist' do
      let(:offer_settings) { create :offer_settings, logistics_customizations: {} }

      it 'shows the correct message' do
        expect(edit_page).to have_content 'No logistics customizations available for this record.'
      end
    end

    context 'when logistics customizations exist' do
      it 'shows the logistics customizations table' do
        expect(edit_page).to have_css 'table.logistics-customizations-table'
        within('table.logistics-customizations-table') do
          offer_settings.logistics_customizations.each do |key, _values|
            expect(page).to have_css('td', text: key.titleize)
          end
        end
      end
    end
  end
end
