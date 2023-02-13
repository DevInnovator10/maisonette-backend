# frozen_string_literal: true

module Spree::Admin::ReturnReasonsController::IncludesOrderManagementEntity
  def collection
    super.includes(:order_management_entity)
  end
end
