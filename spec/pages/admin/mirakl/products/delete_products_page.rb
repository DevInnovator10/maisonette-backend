# frozen_string_literal: true

module Admin
    module Maisonette
    module Mirakl
      class DeleteProductsPage < SitePrism::Page
        set_url '/admin/mirakl/delete_products'

        element :delete_products_form, '.delete-products-form'

        def select_file(file, search: false)
          within(delete_products_form) do
            attach_file 'file', Rails.root + "spec/fixtures/files/mirakl/#{file}"
            find("input[type='submit']").click if search
          end
        end
      end
    end
  end
end
