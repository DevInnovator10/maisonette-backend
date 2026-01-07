# frozen_string_literal: true

module Mirakl
  class ProductsExportErrorReportInteractor < ApplicationInteractor
    include Mirakl::Api

    def call
      response = get("/products/synchros/#{context.synchro_id}/error_report")

      context.csv_response = CSV.parse(response.body, col_sep: ';', headers: true)
    end

  end
end
