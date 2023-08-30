# frozen_string_literal: true

module Admin
  module Products
    module Stock
      class IndexPage < SitePrism::Page
        set_url '/admin/products/{slug}/stock'

        element :variant_stock_row, 'tbody.variant-stock-items tr'
        element :stock_location_select, 'select[name=stock_location_id]'
        element :backorderable_checkbox, 'input[name=backorderable]'
        element :count_on_hand, 'input[name=count_on_hand]'
        element :add_stock_button, 'a[data-action=add].submit'
      end
    end
  end
end
