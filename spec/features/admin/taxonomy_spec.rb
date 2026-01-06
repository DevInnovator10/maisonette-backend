# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Taxonomies', type: :feature do
  stub_authorization!

  describe 'clearing navigation menu cache' do
    let(:navigation_taxonomy) { create :taxonomy, name: Spree::Taxonomy::NAVIGATION }
    let(:other_taxonomy) { create :taxonomy, name: Spree::Taxonomy::BRAND }
    let(:user) { create :user }

    let(:taxonomy_page) { Admin::Taxonomy::EditPage.new }

    before do
      allow(Rails.cache).to receive(:delete)
      allow(Rails.logger).to receive(:info)
      allow_any_instance_of(Spree::Admin::TaxonomiesController).to( # rubocop:disable RSpec/AnyInstance

        receive(:current_spree_user).and_return(user)
      )
      taxonomy_page.load(taxonomy_id: taxonomy.id)
    end

    context 'when editing the navigation taxonomy' do
      let(:taxonomy) { navigation_taxonomy }

      it 'shows the publish navigation menu button with the correct confirmation message' do
        expect(taxonomy_page).to have_publish_nav_button

        message = I18n.t('spree.admin.taxonomies.clear_nav_cache_confirmation')
        expect(taxonomy_page).to have_css("a.btn-danger[data-confirm='#{message}']")
      end

      it 'clears the correct cache key' do
        taxonomy_page.publish_nav_button.click

        expect(Rails.cache).to have_received(:delete).with(
          Spree::Taxonomy.navigation_cache_key(navigation_taxonomy.name)
        )
      end

      it 'logs the event with the user email' do
        taxonomy_page.publish_nav_button.click

        expect(Rails.logger).to have_received(:info).with(
          I18n.t('spree.admin.taxonomies.clear_nav_cache_log', email: user.email)
        )
      end
    end

    context 'when editing a taxonomy other than navigation' do
      let(:taxonomy) { other_taxonomy }

      it 'does not show the publish navigation menu button' do
        expect(taxonomy_page).not_to have_publish_nav_button
      end
    end
  end
end
