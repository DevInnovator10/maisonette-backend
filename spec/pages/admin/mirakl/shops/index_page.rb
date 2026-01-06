# frozen_string_literal: true

module Admin
  module Mirakl
    module Shops
      class IndexPage < SitePrism::Page
        set_url '/admin/mirakl/shops'

        section :content_header, Admin::ContentHeaderSection, '#content-header'

        # Actions
        element :mirakl_shop_delta_sync_btn, '.mirakl-shops-delta-sync-btn'

        # Filters
        element :name_filter, '#q_name_cont'
        element :shop_number_filter, '#q_shop_id_eq'
        element :shop_id_filter, '#q_id_eq'

        element :filter_button, "[data-hook='admin_mirakl_shops_index_search_buttons']"
      end
    end
  end
end
