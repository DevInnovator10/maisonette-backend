# frozen_string_literal: true

module Admin
  module Products
    module Prices
      class EditPage < SitePrism::Page
        set_url '/admin/products/{id}/prices/new'

        element :vendor_selector, "select[id='price_vendor_id']"

        section :form_actions, Admin::FormButtonsActionsSection, "[data-hook='buttons']"

        def select_vendor(name)
          vendor_selector.select(name)
        end
      end
    end
  end
end
