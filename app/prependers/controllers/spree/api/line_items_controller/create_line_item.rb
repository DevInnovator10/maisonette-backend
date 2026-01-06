# frozen_string_literal: true

module Spree::Api::LineItemsController::CreateLineItem
  def create
    context = Orders::AddToCartInteractor.call(
      order: @order, line_item_params: line_item_params, added_by: current_api_user
    )

    if context.success?
      render partial: 'spree/api/line_items/line_item', locals: { line_item: context.line_item }, status: :created
    else
      render json: { error: context.message }, status: :unprocessable_entity
    end
  rescue StandardError => e
    handle_standard_error(e)
  end

  private

  def handle_standard_error(exception)
    extra = {
      line_item_params: line_item_params,
      order_number: @order.number,
      added_by: current_api_user&.id
    }

    Sentry.capture_exception_with_message(exception, extra: extra)
    render json: { error: exception.message }, status: :unprocessable_entity
  end

  def line_item_params
    item_params = super
    {
      variant_id: item_params.dig('variant_id'),
      quantity: item_params.dig('quantity'),
      vendor_id: item_params.dig('options', 'vendor_id')
    }
  end
end
