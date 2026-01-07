# frozen_string_literal: true

module Admin
  module Mirakl
    module Orders
      class EditPage < SitePrism::Page
        set_url '/admin/mirakl/orders/{id}/edit'

        section :content_header, Admin::ContentHeaderSection, '#content-header'

        # Actions
        element :cancel_order_btn, '.mirakl-orders-cancel-order-btn'
        element :recreate_easypost_label_btn, '.mirakl-orders-recreate-easypost-label-btn'
        element :fetch_easypost_errors_label_btn, '.mirakl-orders-fetch-easypost-errors-btn'
        element :send_packing_slip_btn, '.mirakl-orders-send-packing-slip-btn'
      end
    end
  end
end
