# frozen_string_literal: true

module Admin
  module Products
    class IndexPage < SitePrism::Page
      set_url '/admin/products'

      section :content_header, Admin::ContentHeaderSection, '#content-header'

      element :search_button, '[data-hook="admin_products_index_search_buttons"] button'
      element :availability_select, '.select2-container.select2.availability'
      element :stock_location_select, '.select2-container.select2.stock_items_stock_location_id_eq'
      element :vendor_or_maisonette_sku,
              '#q_variants_offer_settings_vendor_sku_or_variants_offer_settings_maisonette_sku_cont'

      def select_availability(scope)
        availability_select.click
        find('.select2-results li', text: scope).click
      end

      def select_stock_location(name)
        stock_location_select.click
        find('.select2-results li', text: name).click
      end
    end
  end
end
