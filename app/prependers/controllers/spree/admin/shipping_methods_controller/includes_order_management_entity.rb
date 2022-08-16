# frozen_string_literal: true

module Spree::Admin::ShippingMethodsController::IncludesOrderManagementEntity
  def collection
    super.includes(:order_management_entity)
  end
end
