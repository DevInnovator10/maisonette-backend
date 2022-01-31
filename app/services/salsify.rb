# frozen_string_literal: true

require 'csv'

module Salsify
  REGEXP_FILE_DATE = /.+_(\d{4}-\d{2}-\d{2}.*)\.csv\Z/.freeze

  ACTIONS = %w[N U VD PD].freeze

  # Headers for a New action
  NEW_HEADERS = [
    'Action',
    'Item Name',
    'Maisonette Retail',
    'Maisonette SKU',
    'Parent ID',
    'Vendor Name'
  ].freeze

  # Headers for an Update action
  UPDATE_HEADERS = [
    'Action',
    'Item Name',
    'Maisonette SKU',
    'Parent ID'
  ].freeze

  # Required taxonomies
  TAXONOMIES = [
    'Age Range',
    'Brand',
    'Category',
    'Color',
    'Edits',
    'Gender',
    'Internal Gender',
    'Looks',
    'Main Category',
    'Product Type',
    'Season',
    'Selling Group',
    'Trends',
    'Type'
  ].freeze

  PRODUCT_PROPERTIES = [
    'Assembly Required',
    'Bed Size Options',
    'Size Guide',
    'Care Instructions',
    'Country of Origin',
    'Tariff Codes',
    'Internal Group',
    'Internal Brand',
    'Maisonette Product ID',
    'Backorder Date',
    'MSRP',
    'Margin',
    'Material',
    'Maternity',
    'Made to Order',
    'Packaging Type',
    'Number of Boxes',
    'Box1 Packaged Weight',
    'Box1 Packaged Length',
    'Box1 Packaged Width/Depth',
    'Box1 Packaged Height',
    'Box2 Packaged Weight',
    'Box2 Packaged Length',
    'Box2 Packaged Width/Depth',
    'Box2 Packaged Height',
    'Box3 Packaged Weight',
    'Box3 Packaged Length',
    'Box3 Packaged Width/Depth',
    'Box3 Packaged Height',
    'Season',
    'State Shipping Restrictions',
    'Sizing Notes',
    'UPC Barcode',
    'Vendor Recommended Ship Method',
    'Pet Type',
    'ASIN',
    'Holiday',
    'Exclusive Definition'
  ].freeze

  MULTI_VALUE_PRODUCT_PROPERTIES = [
    'Awards',
    'Key Ingredients & Benefits',
    'Full List of Ingredients',
    'Good to know',
    'How to Use'
  ].freeze

  def self.parse_csv_file(file_path)
    path = file_path.is_a?(Pathname) ? file_path : Pathname.new(file_path)
    CSV.parse(
      path.read,
      headers: true,
      encoding: 'UTF-8',
      header_converters: ->(h) { h.strip }
    )
  end

  def self.salsify_error(key, instance: nil, prefix: 'Salsify error')
    [prefix, instance&.class&.name, I18n.t('errors.salsify')[key]].compact.join(' - ')
  end

  def self.product_name(salsify_row_data)
    full_item_name = sanitized_item_name(salsify_row_data)

    splitted_name = full_item_name.split(',')

    return full_item_name if splitted_name.count == 1

    splitted_name[0..-2].join(',')
  end

  def self.main_option_value_name(salsify_row_data)
    full_item_name = sanitized_item_name(salsify_row_data)
    full_item_name.split(',')[-1].strip
  end

  def self.main_option_type_name
    'Color'
  end

  def self.sanitized_item_name(salsify_row_data)
    salsify_row_data['Item Name'].dup.force_encoding('UTF-8')
  end

  def self.valid_date_for(str)
    Salsify.chronic_config
    Chronic.parse(str)
  rescue StandardError
    nil
  end

  def self.chronic_config
    @chronic_config ||= Time.zone = 'Eastern Time (US & Canada)' && Chronic.time_class = Time.zone
  end
end
