# frozen_string_literal: true

module Admin
  module Maisonette
    module Sales
      class IndexPage < SitePrism::Page
        set_url '/admin/sales'

        element :maisonette_sales_list, "[data-hook='admin_maisonette_sales_index_rows']"
        element :maisonette_sales_list_icons, "[data-hook='admin_maisonette_sales_index_row_actions']"

        section :content_header, Admin::ContentHeaderSection, '#content-header'

        def new_sale_button
          content_header.primary_button
        end

        def download_template_button
          content_header.find('.btn-info', text: 'Download Template')
        end

        def sale(text)
          maisonette_sales_list.find('a', text: text)
        end

        def bulk_edit_link
          maisonette_sales_list.find('a', text: 'Bulk edit')
        end

        def edit_link
          maisonette_sales_list_icons.find('a[class="edit fa fa-edit icon_link with-tip no-text"]')
        end
      end
    end
  end
end
