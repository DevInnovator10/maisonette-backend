# frozen_string_literal: true

module Admin
  module Maisonette
    module VariantGroupAttributes
      class EditPage < SitePrism::Page
        set_url '/admin/products{/product_slug}/variant_group_attributes{/variant_group_attributes_id}/edit'

        section :form, Admin::VariantGroupAttributesFormSection, '#variant_group_attributes_form'
      end
    end
  end
end
