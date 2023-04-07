# frozen_string_literal: true

module Admin
  module OfferSettings
    class NewPage < SitePrism::Page
      set_url '/admin/products{/product_slug}/offer_settings/new'

      section :form, Admin::OfferSettingsFormSection, '#offer_settings_form'
    end
  end
end
