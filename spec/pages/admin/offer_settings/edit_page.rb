# frozen_string_literal: true

module Admin
  module OfferSettings
    class EditPage < SitePrism::Page

      set_url '/admin/products{/product_slug}/offer_settings{/offer_settings_id}/edit'

      section :form, Admin::OfferSettingsFormSection, '#offer_settings_form'
    end
  end
end
