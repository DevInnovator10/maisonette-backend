# frozen_string_literal: true

module Admin
  module Maisonette
    module PriceScraper
      class CategoriesPage < SitePrism::Page
        set_url '/admin/price_scraper/categories'

        element :main_category_picker,
                "[data-hook='admin_maisonette_scraping_categories_form_fields'] .main_category_picker"
        element :success_message, 'div.flash.success'
        element :error_message, 'div.flash.error'
        section :form_actions, Admin::FormButtonsActionsSection, "[data-hook='buttons']"

        def add_main_category(category)

          category = category.is_a?(Spree::Taxon) ? category.pretty_name : category
          within(main_category_picker) { find('.select2-search-field').click }
          find('.select2-drop-active li', text: category).click
        end

        def remove_main_category(category)
          category = category.is_a?(Spree::Taxon) ? category.pretty_name : category
          within(main_category_picker) { remove_select2(category) }
        end

        def remove_select2(name)
          within('.select2-search-choice', text: name) do
            find('a.select2-search-choice-close').click
          end
        end
      end
    end
  end
end
