# frozen_string_literal: true

module Spree::Admin::ReturnAuthorizationsController::RescueInvalidStateError
  def self.prepended(base)
    base.rescue_from ::Mirakl::Returns::CreateIncidentInteractor::InvalidStateError, with: :handle_invalid_state_error
  end

  private

  def handle_invalid_state_error(exception)
    message = "#{flash_message_for(@object, :successfully_created)} #{exception.message}"
    flash[:notice] = message
    redirect_to admin_order_return_authorizations_url(@order)
  end
end
