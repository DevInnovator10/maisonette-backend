# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Taxon Management', type: :feature do
    stub_authorization!

  let(:taxon_edit_page) { Admin::Taxon::EditPage.new }
  let(:taxon_new_page) { Admin::Taxon::NewPage.new }

  describe 'setting navigation menu properties' do
    let(:navigation) { create :taxonomy, name: 'Navigation' }

    let(:brand) { create :taxonomy, name: 'Brand' }
    let(:brand_nav) { create :taxon, name: 'brand_1', parent: brand.root, taxonomy: brand }

    let(:color) { create :taxonomy, name: 'Color' }
    let(:color_nav) { create :taxon, name: 'color_1', parent: color.root, taxonomy: color }

    let(:category_nav) { create :taxon, name: 'category1', parent: navigation.root, taxonomy: navigation }
    let(:category_header) { create :taxon, name: 'category1_child', parent: category_nav, taxonomy: navigation }
    let(:category_menu_item) do
      create :taxon, name: 'category_menu_item', parent: category_header, taxonomy: navigation
    end

    it 'admin should be able to edit taxon' do
      visit spree.new_admin_taxonomy_path

      fill_in 'Name', with: 'Hello'
      click_button 'Create'

      taxonomy = Spree::Taxonomy.last

      visit spree.edit_admin_taxonomy_taxon_path(taxonomy, taxonomy.root.id)

      fill_in 'taxon_name', with: 'Shirt'
      fill_in 'taxon_description', with: 'Discover our new rails shirts'

      fill_in 'permalink_part', with: 'shirt-rails'
      click_button 'Update'
      expect(page).to have_content('has been successfully updated!')
    end

    context 'when an icon exists' do
      let(:category_nav) { create :taxon, :with_icon, name: 'category1', parent: navigation.root, taxonomy: navigation }

      before do
        Fog.mock!
        Fog::Mock.reset

        taxon_edit_page.load(taxonomy_id: category_nav.taxonomy_id, taxon_id: category_nav.id)
      end

      it 'can remove the icon' do
        expect(category_nav.icon).to be_present

        taxon_edit_page.remove_icon_checkbox.click
        click_button 'Update'

        expect(category_nav.reload.icon).not_to be_present
      end
    end

    context 'when an icon does not exist' do
      it 'does not have the remove icon checkbox' do
        taxon_edit_page.load(taxonomy_id: category_nav.taxonomy_id, taxon_id: category_nav.id)

        expect(taxon_edit_page).not_to have_remove_icon_checkbox
      end
    end

    it 'navigation menu options for category taxons' do
      taxon_edit_page.load(taxonomy_id: category_nav.taxonomy_id, taxon_id: category_nav.id)

      expect(page).to have_content 'Navigation Menu Options'
      expect(taxon_edit_page).to have_hidden_checkbox
      expect(taxon_edit_page).to have_highlight_checkbox
    end

    it 'does not show navigation menu options for other taxons' do
      taxon_edit_page.load(taxonomy_id: color_nav.taxonomy_id, taxon_id: color_nav.id)

      expect(page).not_to have_content 'Navigation Menu Options'
      expect(taxon_edit_page).not_to have_highlight_checkbox
    end

    it 'hidden is available for all taxons' do
      taxon_edit_page.load(taxonomy_id: color_nav.taxonomy_id, taxon_id: color_nav.id)
      expect(taxon_edit_page).to have_hidden_checkbox

      taxon_edit_page.load(taxonomy_id: category_nav.taxonomy_id, taxon_id: category_nav.id)
      expect(taxon_edit_page).to have_hidden_checkbox

      taxon_edit_page.load(taxonomy_id: brand_nav.taxonomy_id, taxon_id: brand_nav.id)
      expect(taxon_edit_page).to have_hidden_checkbox
    end

    it 'hides linkable header for any other taxons than depth 2' do
      taxon_edit_page.load(taxonomy_id: category_nav.taxonomy_id, taxon_id: category_nav.id)
      expect(taxon_edit_page).not_to have_header_link_checkbox

      taxon_edit_page.load(taxonomy_id: category_header.taxonomy_id, taxon_id: category_header.id)
      expect(taxon_edit_page).to have_header_link_checkbox

      taxon_edit_page.load(taxonomy_id: category_menu_item.taxonomy_id, taxon_id: category_menu_item.id)
      expect(taxon_edit_page).not_to have_header_link_checkbox
    end

    it 'can set linkable header' do
      expect(category_header.header_link).to eq false
      taxon_edit_page.load(taxonomy_id: category_header.taxonomy_id, taxon_id: category_header.id)
      taxon_edit_page.header_link_checkbox.click
      click_button 'Update'

      expect(category_header.reload.header_link).to eq true
    end

    it 'can set highlight on navigation taxons' do
      expect(category_nav.highlight).to eq false
      taxon_edit_page.load(taxonomy_id: category_nav.taxonomy_id, taxon_id: category_nav.id)
      taxon_edit_page.highlight_checkbox.click
      click_button 'Update'

      expect(category_nav.reload.highlight).to eq true
    end

    it 'can set add flair on top level navigation taxons' do
      taxon_edit_page.load(taxonomy_id: category_header.taxonomy_id, taxon_id: category_header.id)
      expect(taxon_edit_page).not_to have_add_flair

      expect(category_nav.add_flair).to eq false
      taxon_edit_page.load(taxonomy_id: category_nav.taxonomy_id, taxon_id: category_nav.id)
      taxon_edit_page.add_flair.click
      click_button 'Update'

      expect(category_nav.reload.add_flair).to eq true
    end

    it 'can set url_override' do
      taxon_edit_page.load(taxonomy_id: category_nav.taxonomy_id, taxon_id: category_nav.id)
      fill_in :taxon_url_override, with: 'foo/bar'
      click_button 'Update'

      expect(category_nav.reload.url_override).to eq 'foo/bar'
    end

    it 'can set track insights on taxon' do
      expect(category_nav.track_insights).to eq false
      taxon_edit_page.load(taxonomy_id: category_nav.taxonomy_id, taxon_id: category_nav.id)
      taxon_edit_page.track_insights.set(true)
      click_button 'Update'

      expect(category_nav.reload.track_insights).to eq true
    end
  end

  describe 'taxon permalink auto-generation', :js do
    let(:brand) { create :taxonomy, name: 'Brand' }
    let(:brand_taxon) do
      create :taxon, name: 'Brand 1', parent: brand.root, taxonomy: brand, permalink_part: permalink_part
    end

    context 'when the taxon has the default permalink part' do
      let(:permalink_part) { 'new-node' }

      it 'navigation menu options for category taxons' do
        taxon_edit_page.load(taxonomy_id: brand.id, taxon_id: brand_taxon.id)

        expect(taxon_edit_page).to have_auto_generate_permalink_checkbox
        expect(taxon_edit_page.auto_generate_permalink_checkbox).to be_checked

        taxon_edit_page.taxon_name_input.native.send_key 'a'

        expect(taxon_edit_page.permalink_part_input.value).to eq 'brand-1a'

        taxon_edit_page.auto_generate_permalink_checkbox.uncheck
        taxon_edit_page.taxon_name_input.native.send_key 'a'

        expect(taxon_edit_page.permalink_part_input.value).to eq 'brand-1a'

        taxon_edit_page.auto_generate_permalink_checkbox.check

        expect(taxon_edit_page.permalink_part_input.value).to eq 'brand-1aa'
      end
    end

    context 'when the taxon has a custom permalink part' do
      let(:permalink_part) { 'brand-1' }

      it 'navigation menu options for category taxons' do
        taxon_edit_page.load(taxonomy_id: brand.id, taxon_id: brand_taxon.id)

        expect(taxon_edit_page).to have_auto_generate_permalink_checkbox
        expect(taxon_edit_page.auto_generate_permalink_checkbox).not_to be_checked

        taxon_edit_page.taxon_name_input.native.send_key 'a'

        expect(taxon_edit_page.permalink_part_input.value).to eq 'brand-1'

        taxon_edit_page.auto_generate_permalink_checkbox.check

        expect(taxon_edit_page.permalink_part_input.value).to eq 'brand-1a'

        taxon_edit_page.taxon_name_input.native.send_key 'a'

        expect(taxon_edit_page.permalink_part_input.value).to eq 'brand-1aa'
      end
    end
  end

  describe 'when visting new taxon page', :js do
    let(:brand) { create :taxonomy, name: 'Brand' }

    it 'can access it through Add taxon button' do
      visit spree.edit_admin_taxonomy_path(brand.id)

      click_on('Add taxon')

      expect(page).to have_content('New Taxon')
    end

    it 'can create a new taxon' do
      brand_taxon = brand.taxons.first
      taxon_new_page.load(taxonomy_id: brand.id, parent_id: brand_taxon.id)
      taxon_new_page.name_field.set 'Foo Taxon'
      taxon_new_page.permalink_field.set 'bar-taxon'

      click_on('Create')

      taxon = Spree::Taxon.last
      expect(taxon.name).to eq('Foo Taxon')
      expect(taxon.permalink).to eq('brand/bar-taxon')
      expect(taxon.parent).to eq(brand_taxon)
    end

    it 'can create a new taxon with auto generated permalink' do
      brand_taxon = brand.taxons.first
      taxon_new_page.load(taxonomy_id: brand.id, parent_id: brand_taxon.id)
      taxon_new_page.name_field.set 'Foo Taxon'
      taxon_new_page.auto_generate_permalink.check

      click_on('Create')

      taxon = Spree::Taxon.last
      expect(taxon.name).to eq('Foo Taxon')
      expect(taxon.permalink).to eq('brand/foo-taxon')
      expect(taxon.parent).to eq(brand_taxon)
    end

    it 'cannot create a invalid taxon' do
      brand_taxon = brand.taxons.first
      taxon_new_page.load(taxonomy_id: brand.id, parent_id: brand_taxon.id)
      taxon_new_page.name_field.set ''

      click_on('Create')

      expect(page).to have_content("Name can't be blank")
    end

    it 'cannot create a taxon with a taken permalink' do
      brand_taxon = brand.taxons.first
      create(:taxon, permalink: 'foo-taxon', taxonomy_id: brand.id, parent_id: brand_taxon.id)
      taxon_new_page.load(taxonomy_id: brand.id, parent_id: brand_taxon.id)
      taxon_new_page.name_field.set 'Bar Taxon'
      taxon_new_page.permalink_field.set 'foo-taxon'

      click_on('Create')

      expect(page).to have_content('Permalink has already been taken')
    end

    it 'cannot create a taxon with a taken auto generated permalink' do
      brand_taxon = brand.taxons.first
      create(:taxon, permalink: 'foo-taxon', taxonomy_id: brand.id, parent_id: brand_taxon.id)
      taxon_new_page.load(taxonomy_id: brand.id, parent_id: brand_taxon.id)
      taxon_new_page.name_field.set 'Foo Taxon'
      taxon_new_page.auto_generate_permalink.check

      click_on('Create')

      expect(page).to have_content('Permalink has already been taken')
    end
  end
end
