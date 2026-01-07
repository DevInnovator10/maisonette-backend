# frozen_string_literal: true

module Admin
  module Maisonette
    module SaleSkuConfigurations
      class IndexPage < SitePrism::Page
        set_url '/admin/sales/{sale_id}/sale_sku_configurations'

        element :maisonette_sale_sku_configurations_list, "[data-hook='admin_maisonette_sale_sku_configurations_rows']"
        element :taxon_filter, "[data-hook='admin_maisonette_sale_sku_configuration_index_taxons_search'] .taxon_picker"
        element :vendor_filter,
                "[data-hook='admin_maisonette_sale_sku_configuration_index_vendors_search'] .vendor_picker"
        element :created_by_filter,
                "[data-hook='admin_maisonette_sale_sku_configuration_index_created_by_search']"
        element :updated_by_filter,
                "[data-hook='admin_maisonette_sale_sku_configuration_index_updated_by_search']"
        element :percent_off_filter, '#q_config_for_percent_off_eq'
        element :in_stock_filter, '#q_in_stock'
        element :date_filter, '.date-range-filter #q_active_on'
        element :search_button, "button[type='submit']", text: 'Search'
        element :search_with_csv_button, "button[type='button']", text: 'Search w/ CSV'
        element :search_with_csv_modal, '#search-by-csv'
        element :export_button, "button[type='submit']", text: 'Export'
        element :default_configuration_form,
                "[data-hook='admin_maisonette_sale_sku_configuration_default_configuration_form']"
        element :default_configuration_button,
                "[data-hook='admin_maisonette_sale_sku_configuration_default_configuration_buttons'] button"
        element :breadcrumb, '.breadcrumb'
        element :delete_button, '.sales_products_delete_btn', text: 'Delete Products'
        element :delete_all_button, '.sales_products_delete_all_btn', text: 'Delete All Products'

        def filter_by_percent_off(value, search: false)
          percent_off_filter.set value
          perform_search if search
        end

        def filter_by_date(date, search: false)
          date.is_a?(Date) ? date.to_s : date
          date_filter.set date
          perform_search if search
        end

        def filter_by_in_stock(value, search: false)
          in_stock_filter.set value
          perform_search if search
        end

        def filter_by_taxon(taxon, search: false)
          within(taxon_filter) { find('.select2-search-field').click }
          taxon = taxon.is_a?(Spree::Taxon) ? taxon.pretty_name : taxon
          find('.select2-drop-active li', text: taxon).click
          perform_search if search
        end

        def remove_taxon(taxon)
          taxon = taxon.is_a?(Spree::Taxon) ? taxon.pretty_name : taxon
          within(taxon_filter) { remove_select2(taxon) }
        end

        def filter_by_vendor(vendor, search: false)
          within(vendor_filter) { find('.select2-search-field').click }
          vendor = vendor.is_a?(Spree::Vendor) ? vendor.name : vendor
          find('.select2-drop-active li', text: vendor).click
          perform_search if search
        end

        def remove_vendor(vendor)
          vendor = vendor.is_a?(Spree::Vendor) ? vendor.name : vendor
          within(vendor_filter) { remove_select2(vendor) }
        end

        def filter_by_created_by(email, search: false)
          within(created_by_filter) { find('.select2-input').set(email) }
          find('.select2-drop-active li', text: email).click
          perform_search if search
        end

        def remove_created_by(email)
          within(created_by_filter) { remove_select2(email) }
        end

        def filter_by_updated_by(email, search: false)
          within(updated_by_filter) { find('.select2-input').set(email) }
          find('.select2-drop-active li', text: email).click
          perform_search if search
        end

        def remove_updated_by(email)
          within(updated_by_filter) { remove_select2(email) }
        end

        def remove_select2(name)
          within('.select2-search-choice', text: name) do
            find('a.select2-search-choice-close').click
          end
        end

        def select_file(file, search: false)
          search_with_csv_button.click
          within(search_with_csv_modal) do
            attach_file 'file', Rails.root + "spec/fixtures/files/maisonette_sale/#{file}"
            find("button[type='submit']").click if search
          end
        end

        def delete_one_product
          first('.sales_products_checkbox').click
          delete_button.click
        end

        def delete_multiple_products
          all('.sales_products_checkbox').each(&:click)
          delete_button.click
        end

        def select_all_products
          find('.parent_sales_products_checkbox').click
          delete_button.click
        end

        def delete_all_products
          delete_all_button.click
        end

        def perform_search
          search_button.send_keys :tab
          search_button.click
        end

        def fill_in_configuration_form(params)
          within(default_configuration_form) do
            fill_in 'sale_name', with: params[:name] if params[:name]
            fill_in 'sale_percent_off', with: params[:percent_off] if params[:percent_off]
            fill_in 'sale_maisonette_liability', with: params[:maisonette_liability] if params[:maisonette_liability]
            fill_in 'sale_start_date', with: params[:start_date] if params[:start_date]
            check 'sale_final_sale' if params[:final_sale]
          end
        end
      end
    end
  end
end
