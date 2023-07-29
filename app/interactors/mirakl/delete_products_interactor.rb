# frozen_string_literal: true

module Mirakl
  class DeleteProductsInteractor < ApplicationInteractor
    required_params :products_file
    helper_methods :products_file, :csv

    before :validate_context

    def call
      products_file = Mirakl::BinaryFileStringIO.new(csv_with_update_delete.to_csv(col_sep: ';'), products_file_name)

      context.synchro_id = Mirakl::ExportProductsInteractor.call!(products_file: products_file).synchro_id
    rescue StandardError => e
      Sentry.capture_exception_with_message(e)
      context.fail!(message: e.message)
    end

    private

    def validate_context
      context.csv = CSV.read(products_file, headers: true)

      context.fail!(message: 'The uploaded file is empty') if csv.empty?
      context.fail!(message: 'File must have a single product-sku column') if csv.headers != ['product-sku']
    end

    def products_file_name
      "maisonette_manual_products_delete_#{DateTime.now.to_i}.csv"
    end

    def csv_with_update_delete
      csv.each do |row|
        row['update-delete'] = 'delete'
      end
    end
  end
end
