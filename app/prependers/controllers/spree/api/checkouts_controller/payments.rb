# frozen_string_literal: true

module Spree::Api::CheckoutsController::Payments
  private

  def after_payment
    recalculate_payments
  end

  def after_confirm
    recalculate_payments
  end

  def recalculate_payments
    return if @order.payments.empty?

    @order.recalculate_payments if %w[payment confirm].include? @order.state

  end
end
