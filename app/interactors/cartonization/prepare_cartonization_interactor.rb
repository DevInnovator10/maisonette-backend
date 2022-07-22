# frozen_string_literal: true

module Cartonization
    class PrepareCartonizationInteractor < ApplicationInteractor
    helper_methods :mirakl_shop, :mirakl_order

    before :validate_box_types, :validate_cartonization_data

    def call
      parse_box_types
      set_line_items
      set_mailer_eligibility
      context.chosen_boxes = []
    end

    private

    def validate_box_types
      return if mirakl_shop.box_sizes.present?

      error_details = { message: 'Missing cartonization box sizes', vendor: mirakl_shop.name }
      Rails.logger.info error_details
      context.fail!(message: error_details)
    end

    def validate_cartonization_data
      invalid_line_items = mirakl_order.shipment.line_items.select { |li| li.internal_package_dimensions.blank? }
      return if invalid_line_items.empty?

      error_details = {
        message: 'Missing cartonization dimensions',
        vendor: mirakl_shop.name,
        vendor_skus: invalid_line_items.map(&:offer_settings).map(&:vendor_sku)
      }
      Rails.logger.info error_details
      context.fail!(message: error_details)
    end

    def parse_box_types
      context.available_mailers,
      context.available_box_sizes = mirakl_shop.box_sizes.partition { |name| name.starts_with? 'mailer' }
    end

    def set_line_items
      context.ships_alone_line_items,
      context.cartonized_line_items = mirakl_order.shipment.line_items.partition { |li| li.offer_settings.ships_alone }
    end

    def set_mailer_eligibility
      context.ships_in_mailer = context.available_mailers.present? &&
                                context.cartonized_line_items.any? &&
                                context.cartonized_line_items.all? { |li| li.offer_settings.ships_in_mailer }
    end
  end
end
