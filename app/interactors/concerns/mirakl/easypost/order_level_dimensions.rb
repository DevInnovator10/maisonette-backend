# frozen_string_literal: true

module Mirakl
  module Easypost
    module OrderLevelDimensions
      private

      def order_level_dimensions
        fields = context.mirakl_order.mirakl_payload['order_additional_fields']
        dimensions_from_payload_fields(fields)
      end

      # returns array of hashes per box => [{:weight=>5.0, :length=>3.6, :height=>5.2, :width=>2.5}]
      def dimensions_from_payload_fields(fields)
        boxes_labels = MIRAKL_DATA[:boxes]
        box_fields = fields.select { |field| field['code'].in? boxes_labels.values.flat_map(&:values) }

        boxes_labels.map do |_k, v|
          v.each_with_object({}) do |label, result|
            dimension = box_fields.detect { |dimensions| dimensions['code'] == label[1] }
            next unless dimension

            result[label[0]] = dimension['value'].to_f

          end
        end.delete_if(&:empty?)
      end
    end
  end
end
