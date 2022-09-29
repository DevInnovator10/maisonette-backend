# frozen_string_literal: true

module Mirakl
  module Returns
    class CreateIncidentInteractor < ApplicationInteractor
      class InvalidStateError < StandardError; end

      ALLOWED_STATES = %w[SHIPPING SHIPPED RECEIVED].freeze

      def call
        return if mirakl_order_lines.blank?

        open_new_incident_and_update_order_line
        check_invalid_state_order_lines
      end

      private

      def return_authorization
        context.return_authorization
      end

      def mirakl_order_lines
        @mirakl_order_lines ||= Mirakl::OrderLine.part_of_return_authorization(return_authorization)
      end

      def valid_mirakl_order_lines
        @valid_mirakl_order_lines ||= mirakl_order_lines.select { |order_line| order_line.state.in?(ALLOWED_STATES) }
      end

      def invalid_mirakl_order_lines
        @invalid_mirakl_order_lines ||= mirakl_order_lines.reject { |order_line| order_line.state.in?(ALLOWED_STATES) }
      end

      def quantity(line_item)
        return_authorization.return_items.line_item_return_quantity(line_item)
      end

      def logistic_order_id
        mirakl_order_lines[0].order.logistic_order_id
      end

      def return_authorization_hash
        @return_authorization_hash ||= {
          ra_number: return_authorization.number,
          ra_tracking: return_authorization.tracking_number,
          order_lines: []
        }
      end

      def open_new_incident_and_update_order_line
        return if valid_mirakl_order_lines.blank?

        valid_mirakl_order_lines.each do |order_line|
          Mirakl::Returns::OpenNewIncidentInteractor.call(mirakl_order_line: order_line)
          order_line.update(return_authorization: return_authorization)

          return_authorization_hash[:order_lines] << { order_line_id: order_line.mirakl_order_line_id,
                                                       quantity: quantity(order_line.line_item) }
        end

        Mirakl::Returns::UpdateOrderLineRAInteractor.call(mirakl_order_id: logistic_order_id,
                                                          return_authorization_hash: return_authorization_hash)
      end

      def check_invalid_state_order_lines
        return if invalid_mirakl_order_lines.blank?

        order_lines_with_state = invalid_mirakl_order_lines.map do |order_line|
          "#{order_line.mirakl_order_line_id} (#{order_line.state})"
        end.join(', ')
        error_message = I18n.t('mirakl.invalid_order_line_state', order_lines: order_lines_with_state)

        raise InvalidStateError, error_message
      end
    end
  end
end
