# frozen_string_literal: true

module OrderManagement
  class UpsertShipmentsInteractor < ApplicationInteractor
    required_params :mirakl_order
    helper_methods :mirakl_order, :include_items, :status

    before :set_defaults, :validate_context

    def call
      context.response = OrderManagement::ClientInterface.post_composite_for(payload)
    rescue StandardError => e
      context.fail!(error: e.message)
    end

    private

    def set_defaults
      context.include_items = true if context.include_items.nil?
    end

    def validate_context
      context.fail!(error: "Mirakl order required in #{self.class.name}") if mirakl_order.blank?
    end

    def payload
      context.payload ||= OrderManagement::ShipmentsPresenter.new(
        mirakl_order,
        include_items: include_items,
        status: status,
        api_version: OrderManagement::ClientInterface.api_version
      ).payload
    end
  end
end
