# frozen_string_literal: true

module Admin
  module Mirakl
    module Offers
      class IndexPage < SitePrism::Page
        set_url '/admin/mirakl/offers'

        section :content_header, Admin::ContentHeaderSection, '#content-header'

        # Actions
        element :delta_datetime_textfield, '.delta_datetime_textfield'
        element :mirakl_offers_delta_sync_btn, '.mirakl-offers-delta-sync-btn'
        element :mirakl_offers_full_sync_btn, '.mirakl-offers-full-sync-btn'

        # Filters
        element :sku_filter, '#q_sku_cont'
        element :offer_id_filter, '#q_offer_id_eq'
        element :shop_name_filter, '#q_shop_name_eq'

        element :filter_button, "[data-hook='admin_mirakl_import_offers_index_search_buttons']"
      end
    end
  end
end
