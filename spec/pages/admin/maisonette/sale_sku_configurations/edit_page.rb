# frozen_string_literal: true

module Admin
    module Maisonette
    module SaleSkuConfigurations

      class EditPage < SitePrism::Page
        set_url '/admin/sales/{sale_id}/sale_sku_configurations/{/sale_sku_configuration_id}/edit'

        section :form_actions, Admin::FormButtonsActionsSection, "[data-hook='buttons']"

        def fill_form(**params)
          fill_in 'Percent Off', with: params[:percent_off]
          fill_in 'Sale Price', with: params[:static_sale_price]
          fill_in 'Cost Price', with: params[:static_cost_price]
        end
      end
    end
  end
end
