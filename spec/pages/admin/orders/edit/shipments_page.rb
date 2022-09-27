# frozen_string_literal: true

module Admin
  module Orders
    module Edit
      class ShipmentsPage < SitePrism::Page
        include Feature::Select2FeatureHelper

        set_url '/admin/orders/{number}/edit'

        element :on_sale_div, '[data-hook="item-on-sale"]'
        element :final_sale_div, '[data-hook="item-final-sale"]'
        element :variant_sku_link, 'td.item-name [data-hook="sku-link"]'

        element :variant_lead_time, '[data-hook="variant-lead-time"]'
        element :shipment_customer_eta, '[data-hook="shipment-customer-eta"]'

        element :gift_section, '.js-gift-details'

        element :gift_status_label, 'dt[data-hook="admin-order-is-gift"]'
        element :gift_status_value, 'dd#order-is-gift'

        element :variant_selector, '.variant_autocomplete'
        element :add_line_item_div, '#add-line-item'

        section :stock_details, Admin::StockDetailsSection, '#stock_details'
        section :summary_info, Admin::OrderSummarySection, '#order_tab_summary'
        sections :shipments_edit, Admin::ShipmentsEditSection, '.js-shipment-edit'

        def select_shipment(name)
          shipments_edit.find { |s| s.text.match(name) }
        end

        def select_variant(name)
          variant_selector.click

          within '.select2-search' do
            fill_in with: name
          end

          within 'ul.select2-results' do
            find('.select2-result-label', text: name).click
          end
        end
      end
    end
  end
end
