# frozen_string_literal: true

require 'zip'

module Easypost
  class ExtractReportInteractor < ApplicationInteractor
    def call
      unzip
      create_csv_tables
    end

    private

    def unzip
      context.files = {}
      ::Zip::InputStream.open(StringIO.new(context.document)) do |stream|
        while (entry = stream.get_next_entry)
          context.files[entry.name] = stream.read
        end
      end
    end

    def create_csv_tables
      context.csv_tables = []
      context.files.values.each do |content|
        context.csv_tables << CSV.parse(content, col_sep: ',', headers: true)
      end
    end
  end
end
