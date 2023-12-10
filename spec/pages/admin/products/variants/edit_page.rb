# frozen_string_literal: true

module Admin
    module Products
    module Variants
      class EditPage < SitePrism::Page
        set_url '/admin/products/{slug}/variants/{variant_id}/edit'

        element :reprocess_mirakl_offers_btn, "[data-hook='reprocess_mirakl_offers_btn']"
        element :oms_sync_tab, '.oms_sync_tab'
      end
    end
  end
end
