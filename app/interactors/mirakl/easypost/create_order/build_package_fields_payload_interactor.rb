# frozen_string_literal: true

module Mirakl
  module Easypost
    module CreateOrder
      class BuildPackageFieldsPayloadInteractor < ApplicationInteractor
        helper_methods :mirakl_order, :boxes

        def call
          return unless context.update_mirakl

          boxes.each.with_index(1) do |box, i|
            labels = MIRAKL_DATA[:boxes][:"box#{i}"]
            labels.each do |k, v|
              value = box[k]
              next unless value

              formatted_value = value.respond_to?(:round) ? value.round(2) : value
              payload << { code: v, value: formatted_value }
            end
          end
        rescue StandardError => e
          rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        end

        private

        def payload
          context.mirakl_order_additional_fields_payload ||= []
        end
      end
    end
  end
end
