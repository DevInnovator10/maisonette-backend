# frozen_string_literal: true

require 'zip'

module Mirakl
  class RetrieveBiCsvInteractor < ApplicationInteractor
    include Mirakl::Api

    def call
      response = get('/bi?data_type=ORDER_LINE&file_type=CSV')
      context.fail!(message: 'Failed to GET Mirakl Business Intelligence Zip') unless response

      Zip::File.open_buffer(response) do |zip_file|
        zip_file.each do |entry|
          entry.extract(context.csv_directory) { true }
        end
      end
    end
  end
end
