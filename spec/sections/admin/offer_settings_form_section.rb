# frozen_string_literal: true

require_relative './form_buttons_actions_section.rb'

module Admin
  class OfferSettingsFormSection < SitePrism::Section
    element :variant_select, '#offer_settings_variant_id'
    element :vendor_select, '#offer_settings_vendor_id'
    element :vendor_sku, '#offer_settings_vendor_sku'
    element :maisonette_sku, '#offer_settings_maisonette_sku'

    element :monogrammable_only_checkbox, '#offer_settings_monogrammable_only'
    element :monogram_price_number_field, '#offer_settings_monogram_price'
    element :monogram_cost_price_number_field, '#offer_settings_monogram_cost_price'
    element :monogram_lead_time_number_field, '#offer_settings_monogram_lead_time'
    element :monogram_max_text_length_number_field, '#offer_settings_monogram_max_text_length'

    section :form_actions, Admin::FormButtonsActionsSection, "[data-hook='buttons']"
  end
end
