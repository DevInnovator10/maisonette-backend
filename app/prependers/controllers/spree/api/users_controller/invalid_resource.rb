# frozen_string_literal: true

module Spree::Api::UsersController::InvalidResource
  private

  def invalid_resource!(resource)
    Rails.logger.error "invalid_resouce_errors=#{resource.errors.full_messages}"
    render json: { errors: resource.errors.full_messages }, status: 422

  end
end
