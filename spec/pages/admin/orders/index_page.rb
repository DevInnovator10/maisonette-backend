# frozen_string_literal: true

module Admin
  module Orders
    class IndexPage < SitePrism::Page
      set_url '/admin/orders'

      element :order_id_input, 'input#q_id_eq'
      element :filter_button, "[data-hook='admin_orders_index_search_buttons'] button"
    end
  end
end
