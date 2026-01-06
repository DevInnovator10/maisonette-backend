# frozen_string_literal: true

module Mirakl
  class SubmitOrderAdditionalFieldsInteractor < ApplicationInteractor
    include Mirakl::Api

    before :reject_fields

    def call
      return if payload.blank?

      put("/orders/#{context.mirakl_order.logistic_order_id}/additional_fields",
          payload: { order_additional_fields: payload, order_lines: order_line_additional_fields_payload }.to_json)
    rescue StandardError => e
      rescue_and_capture(e, extra: { mirakl_logistic_order_id: context.mirakl_order.logistic_order_id })
    end

    private

    def payload
      context.mirakl_order_additional_fields_payload
    end

    def order_line_additional_fields_payload
      context.order_line_additional_fields_payload || []
    end

    def reject_fields
      payload&.reject! { |field| context.mirakl_order.fetch_additional_field(field[:code]).to_s == field[:value].to_s }
    end
  end
end
