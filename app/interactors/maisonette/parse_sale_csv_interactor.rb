# frozen_string_literal: true

module Maisonette
    class ParseSaleCsvInteractor < ApplicationInteractor
    required_params :sale_id, :file_path
    helper_methods :sale_id, :file_path

    before :validate_context

    def call
      conditions = parse_conditions
      context.collection = conditions.blank? ? Spree::OfferSettings.none : query.where(conditions)
    end

    private

    def validate_context
      context.fail!(message: 'The file is empty') if File.zero?(file_path)
    end

    def query
      ::Spree::OfferSettings
        .includes(:vendor, variant: :product)
        .includes(:sale_sku_configurations)
        .joins(
          ActiveRecord::Base.sanitize_sql(
            ["AND #{::Maisonette::SaleSkuConfiguration.table_name}.sale_id = ?", sale_id]
          )
        )
        .references(:vendor, { variant: :product }, :sale_sku_configuration)
    end

    def parse_conditions
      conditions = ''
      parse_file(file_path) do |row|
        condition = search_string(row)
        if condition.present?
          conditions += ' OR ' unless conditions.empty?
          conditions += "(#{ActiveRecord::Base.sanitize_sql(condition)})"
        end
      end
      conditions
    end

    def search_string(row)
      [
        sanitize_sql("#{::Spree::Product.table_name}.name = ?", row['Product Name']),
        sanitize_sql("#{::Spree::Vendor.table_name}.name = ?", row['Vendor Name']),
        sanitize_sql("#{::Spree::OfferSettings.table_name}.maisonette_sku = ?", row['Maisonette SKU']),
        sanitize_sql("#{::Spree::OfferSettings.table_name}.vendor_sku = ?", row['Vendor SKU'])
      ].compact.join(' AND ')
    end

    def sanitize_sql(string, value)
      return nil if value.nil?

      ActiveRecord::Base.sanitize_sql([string, value])
    end

    def parse_file(file_path)
      ext = File.extname(file_path).delete_prefix('.')

      send("parse_#{ext}", file_path) do |row, index|
        next if index.negative?

        yield(row)
      end
    end

    def parse_csv(file_path, &block)
      CSV.foreach(file_path, headers: true, col_sep: ',').with_index(&block)
    rescue CSV::MalformedCSVError => e
      context.fail!(message: e.message)
    end

    def parse_xlsx(file_path, &block)
      require 'roo'

      Roo::Spreadsheet.open(file_path).sheet(0).each(
        header_search: ['Product Name', 'Vendor Name', 'Maisonette SKU', 'Vendor SKU']
      ).with_index(-1, &block) # Discard the first row because it's the header
    rescue Zip::Error => e
      context.fail!(message: e.message)
    rescue Roo::HeaderRowNotFoundError => e
      context.fail!(message: "missing headers #{e.message}")
    end
  end
end
