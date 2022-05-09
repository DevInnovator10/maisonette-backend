# frozen_string_literal: true

module CurrentOrderConcerns
  extend ActiveSupport::Concern

  include Spree::Core::ControllerHelpers::Order

  private

  def try_spree_current_user
    @try_spree_current_user ||= current_api_user
  end

  def current_order_params
    order_params = super.merge(guest_token: order_token)
    order_params.merge!(browser_analytics: browser_params.to_json) if browser_params.present?
    order_params.merge!(user_id: nil) if logging_in_or_new_user?
    order_params
  end

  def new_order_params
    super.except(:guest_token)
  end

  def logging_in_or_new_user?
    params[:controller] == 'spree/api/users' && %w[create login].include?(params[:action])
  end

  def set_or_associate_current_order
    return unless current_order

    current_api_user_incomplete_orders.any? ? set_current_order : associate_user
    set_new_order if current_order.restart_checkout_flow == :restart_failed
  end

  def current_api_user_incomplete_orders
    try_spree_current_user
      .orders
      .by_store(current_store)
      .incomplete
      .where.not(state: :complete)
      .where('id != ?', current_order.id)
  end

  def set_new_order
    @current_order = Spree::Order.new(new_order_params)
    @current_order.user ||= try_spree_current_user
    @current_order.created_by ||= try_spree_current_user
    @current_order.save!
  end

  def ip_address
    request.headers['X-Forwarded-For'] || request.remote_ip
  end

  def browser_params
    params.fetch(:browser, {}).permit(
      :ab_tests,
      :amplitude_active,
      :ga_active,
      :maisonette_session_token
    )
  end
end
