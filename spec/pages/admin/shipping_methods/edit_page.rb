# frozen_string_literal: true

module Admin
  module ShippingMethods
    class EditPage < SitePrism::Page
      set_url 'admin/shipping_methods/{id}/edit'

      element :delivery_time,
              "[data-hook='admin_shipping_method_form_delivery_time'] input#shipping_method_delivery_time"
      element :grace_period,
              "[data-hook='admin_shipping_method_form_grace_period'] input#shipping_method_grace_period"
      element :mirakl_shipping_method_code,
              "[data-hook='admin_shipping_method_form_mirakl_shipping_method_code'] input#shipping_method_mirakl_shipping_method_code" # rubocop:disable Metrics/LineLength
      element :expedited_flat_rate_adjustment,
              "[data-hook='admin_shipping_method_form_expedited_flat_rate_adjustment'] input#shipping_method_expedited_flat_rate_adjustment" # rubocop:disable Metrics/LineLength
      element :base_flat_rate_amount,
              "[data-hook='admin_shipping_method_form_base_flat_rate_amount'] input#shipping_method_base_flat_rate_amount" # rubocop:disable Metrics/LineLength

      section :form_actions, Admin::FormButtonsActionsSection, "[data-hook='buttons']"
    end
  end
end
