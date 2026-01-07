# frozen_string_literal: true

module Admin
  module Orders
    module Edit
      class CartPage < SitePrism::Page
        include Feature::Select2FeatureHelper

        element :line_item_vendor, '.line-item-vendor-name'
        element :variant_selector, '.select-variant'
        element :vendor_selector, '.select-vendor'
        element :search, '.select2-search'
        element :results, 'ul.select2-results'
        element :waiting_results, 'ul.select2-results li.select2-searching'
        element :add_line_item_button, 'button.js-add-line-item'
        element :oos_status_label, 'dt[data-hook="admin-order-has-oos"]'
        element :oos_status_value, 'dd#oos-item'

        set_url '/admin/orders/{id}/cart'

        def select_variant(name)
          variant_selector.click

          within '.select2-search' do
            fill_in with: name
          end

          within results do
            find('.select2-result-label', text: name).click
          end
        end

        def select_vendor(name)
          select2 name, css: '.select-vendor'
        end

        def update_line_item(name, quantity = 1)
          within('.line-items') do
            find('.edit-line-item').click

            select_vendor(name)

            fill_in 'quantity', with: quantity

            find('.save-line-item').click
          end
        end
      end
    end
  end
end
