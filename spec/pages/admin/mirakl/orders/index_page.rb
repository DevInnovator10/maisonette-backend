# frozen_string_literal: true

module Admin
  module Mirakl
    module Orders
      class IndexPage < SitePrism::Page
        set_url '/admin/mirakl/orders'

        section :content_header, Admin::ContentHeaderSection, '#content-header'

        # Actions
        element :delta_datetime_textfield, '.delta_datetime_textfield'
        element :mirakl_orders_delta_sync_btn, '.mirakl-orders-delta-sync-btn'

        # Filters
        element :logistic_order_id_filter, '#q_logistic_order_id_cont'
        element :id_filter, '#q_id_eq'
        element :incident_filter, '#q_incident_eq'
        element :state_filter, '#q_state_eq'

        element :filter_button, "[data-hook='admin_mirakl_import_orders_index_search_buttons']"
      end
    end
  end
end
