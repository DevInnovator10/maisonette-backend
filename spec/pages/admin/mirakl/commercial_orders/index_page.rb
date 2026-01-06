# frozen_string_literal: true

module Admin
  module Mirakl
    module CommercialOrders
      class IndexPage < SitePrism::Page
        set_url '/admin/mirakl/commercial_orders'

        section :content_header, Admin::ContentHeaderSection, '#content-header'

        # Filters
        element :spree_order_number_filter, '#q_spree_order_number_cont'
        element :id_filter, '#q_id_eq'
        element :commercial_order_id_filter, '#q_commercial_order_id_eq'
        element :status_filter, '#q_state_eq'

        element :filter_button, "[data-hook='admin_mirakl_commercial_orders_index_search_buttons']"

        # Actions
        element :resend_commercial_order_btn do |commercial_order_id|
          "[data-hook='resubmit_#{commercial_order_id}']"
        end
      end
    end
  end
end
