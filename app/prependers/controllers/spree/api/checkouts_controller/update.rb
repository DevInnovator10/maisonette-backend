# frozen_string_literal: true

module Spree::Api::CheckoutsController::Update
  def update
    authorize! :update, @order, order_token
    return invalid_resource!(@order) unless update_order_attributes!

    @order.associate_user!(Spree.user_class.find(user_id)) if can?(:admin, @order) && user_id.present?

    return if after_update_attributes

    add_address_verification if verify_shipping_address

    respond_with_order
  end

  private

  def update_order_attributes!
    add_last_ip_address
    ::Spree::OrderUpdateAttributes.new(@order, update_params, request_env: request.headers.env).apply
  end

  def add_last_ip_address
    params[:order] ||= {}
    params[:order][:last_ip_address] = request.headers['HTTP_CLIENT_IP']
  end

  def update_params
    if (update_params = massaged_params[:order])
      update_params.permit(permitted_checkout_attributes)
    else
      # We current allow update requests without any parameters in them.
      {}
    end
  end

  def respond_with_order
    @order.recompute_shipping if holding_state && @order.completed_at.nil?

    if @order.completed? || holding_state || @order.next
      state_callback :after
      respond_with @order, default_template: 'spree/api/orders/show'
    else
      exception = StandardError.new("#{params} - failed_to_transition_errors=#{@order.errors.full_messages}")
      exception.set_backtrace(caller)
      Sentry.capture_exception_with_message(exception)
      respond_with @order, default_template: 'spree/api/orders/could_not_transition', status: 422
    end
  end

  def holding_state
    (params[:hold_state] == 'true' && @order.recalculate) || @order.confirm?
  end

  def verify_shipping_address
    params[:address_verification] == 'true' && @order&.ship_address&.easypost_address_id.blank?
  end

  def add_address_verification
    @order.address_verification = @order.shipping_address.to_easypost_address!(verify: true)
    @order.shipping_address.update_columns( # rubocop:disable Rails/SkipsModelValidations
      residential: @order.address_verification&.residential
    )
  rescue StandardError => e
    message = "Failed to verify easypost address for #{@order.number}"
    Sentry.capture_exception_with_message(e, message: message)
  end
end
