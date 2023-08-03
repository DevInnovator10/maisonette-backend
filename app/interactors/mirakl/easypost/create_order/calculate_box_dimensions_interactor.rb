# frozen_string_literal: true

module Mirakl
  module Easypost
    module CreateOrder
      class CalculateBoxDimensionsInteractor < ApplicationInteractor
        include Mirakl::Easypost::OrderLevelDimensions

        helper_methods :mirakl_order

        def call
          context.update_mirakl = true

          # Take dimensions from Order level if exists, else from order lines
          context.boxes = if order_level_dimensions?
                            context.update_mirakl = false
                            order_level_dimensions
                          else
                            build_dimensions
                          end

          ensure_box_quantities
          validate_box_dimensions
        rescue StandardError => e
          context.error_message ||= "#{logistic_order_id}: Missing or Invalid box dimensions - #{e.message}"
          rescue_and_capture e, sentry_extras(e)
        end

        private

        def order_level_dimensions?
          box1_labels = MIRAKL_DATA[:boxes][:box1].values
          box1_fields = mirakl_order.mirakl_payload['order_additional_fields'].select do |field|
            field['code'].in? box1_labels
          end
          box1_fields.count >= 4
        end

        def build_dimensions
          if mirakl_shop.cartonize_shipments && cartonization.success?
            cartonization.chosen_boxes
          elsif multiple_box_item
            multi_box_item_dimensions
          else
            Array.wrap(largest_item_dimensions)
          end
        end

        def mirakl_shop
          context.mirakl_shop ||= Mirakl::Shop.find_by(shop_id: mirakl_order.mirakl_payload['shop_id'])
        end

        def cartonization
          Cartonization::PackShipmentOrganizer.call(mirakl_order: mirakl_order, mirakl_shop: mirakl_shop)
        end

        def multi_box_item_dimensions
          dimensions_from_payload_fields(multiple_box_item)
        end

        def multiple_box_item
          @multiple_box_item ||= begin
            number_of_boxes_label = MIRAKL_DATA[:order_line][:additional_fields][:number_of_boxes]

            item = mirakl_order.mirakl_payload['order_lines'].detect do |ol|
              number_of_boxes = ol['order_line_additional_fields'].detect do |field|
                field['code'] == number_of_boxes_label
              end
              next unless number_of_boxes

              number_of_boxes['value'].to_i > 1
            end

            return false unless item

            item['order_line_additional_fields']
          end
        end

        def largest_item_dimensions
          box1_labels = MIRAKL_DATA[:boxes][:box1]

          fields = largest_item(box1_labels)['order_line_additional_fields']

          box1_dims = box1_labels.each_with_object({}) do |label, result|
            result[label[0]] = fields.detect { |field| field['code'] == label[1] }&.[]('value')
          end.compact

          return box1_dims if box1_dims.count >= 4

          fetch_largest_product_dimensions
        end

        def largest_item(box1_labels)
          mirakl_order.mirakl_payload['order_lines'].max_by do |ol|
            ol['order_line_additional_fields']
              .select { |field| field['code'].in? box1_labels.values }
              .map { |dimension| dimension['value'].to_f }
              .sum
          end
        end

        def fetch_largest_product_dimensions # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          largest_order_line = mirakl_order.order_lines.max_by do |order_line|
            order_line.line_item.product.box_properties.map do |box|
              box[1][/\.?\d+(\.\d+)?/].to_f.round(2)
            end
          end

          largest_order_line.line_item.product.box_properties.each_with_object({}) do |box, result|
            box_value = box[1][/\.?\d+(\.\d+)?/].to_f.round(2)
            next unless box_value.positive?

            box_map = { 'Box1 Packaged Weight' => :weight,
                        'Box1 Packaged Length' => :length,
                        'Box1 Packaged Width/Depth' => :width,
                        'Box1 Packaged Height' => :height }
            code = box_map[box[0]]
            result[code] = box_value
          end
        end

        def ensure_box_quantities
          max_allowed_boxes = MIRAKL_DATA[:boxes].length
          return if context.boxes.length <= max_allowed_boxes

          context.boxes = context.boxes[0...max_allowed_boxes]

          box_quantity_message = "#{logistic_order_id}: Maximum box quantity exceeded for cartonization"
          context.error_message = box_quantity_message

          rescue_and_capture(
            ::Mirakl::Easypost::MaxBoxQuantityExceededError.new(box_quantity_message),
            error_details: box_quantity_message,
            extra: { mirakl_logistic_order_id: logistic_order_id, details: box_quantity_message }
          )
        end

        def validate_box_dimensions
          context.boxes.each do |box|
            box.each do |attr, value|
              next if value.to_f.positive? || attr.to_s == 'name'

              error_message = "#{attr} cannot be zero"
              context.error_message = "#{logistic_order_id}: Missing or Invalid box dimensions - #{error_message}"
              raise ::Mirakl::Easypost::InvalidDimensionError, error_message
            end
          end
        end

        def logistic_order_id
          context.logistic_order_id ||= mirakl_order.logistic_order_id
        end

        def sentry_extras(exception)
          { error_details: 'Missing or Invalid box dimensions',
            extra: { mirakl_logistic_order_id: logistic_order_id, details: exception.message } }
        end
      end
    end

    class InvalidDimensionError < StandardError; end
    class MaxBoxQuantityExceededError < StandardError; end
  end
end
