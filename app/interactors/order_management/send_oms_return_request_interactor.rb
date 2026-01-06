# frozen_string_literal: true

module OrderManagement
  class SendOmsReturnRequestInteractor < ApplicationInteractor
    before :validate_context
    before :prepare_context
    after :check_errors

    def call
      process_items(prepare_items(context.request['items']))
    end

    private

    def add_unit(item)
      reason =
        Spree::ReturnReason.find_by(mirakl_code: item['reason_code']) ||
        Spree::ReturnReason.find_by(name: item['reason']) ||
        Spree::ReturnReason.find_by(name: 'Other')

      {
        'reason': reason,
        'line_item_id': item['item_id']
      }
    end

    def create_auth_payload(reason, mirakl_order_line_ids)
      ReturnAuthorizationPresenter.new(mirakl_order_line_ids, reason).payload
    end

    def prepare_context
      context.error_messages = []
    end

    def prepare_items(items)
      return_items = []
      items.each do |item|
        return_items << add_unit(item)
      end
      context.fail!(error: 'No valid shipped items to return') if return_items.empty?
      return_items
    end

    def create_oms_authorization(reason, mirakl_order_line_ids)
      payload = create_auth_payload(reason, mirakl_order_line_ids)
      response = OrderManagement::ClientInterface.post_return_authorization(payload)
      context.fail!(error: response) unless response.response.status == 200
    end

    def get_mirakl_order_line_ids(line_item_ids)
      mirakl_order_line_ids = Mirakl::OrderLine.where(line_item_id: line_item_ids).pluck(:mirakl_order_line_id)

      context.fail!(error: 'No valid line items to return') if mirakl_order_line_ids.empty?
      mirakl_order_line_ids
    end

    def process_items(return_items)
      return_items.group_by { |item| item[:reason] }.each do |reason, items_per_reason|

        item_ids = items_per_reason.pluck(:line_item_id)
        mirakl_order_line_ids = get_mirakl_order_line_ids(item_ids)
        create_oms_authorization(reason, mirakl_order_line_ids)
      end
    end

    def check_errors
      context.fail!(error: context.error_messages.join('; ')) if context.error_messages.any?
    end

    def validate_context
      context.fail!(error: 'Order required') if context.order.blank?
      context.fail!(error: 'Request data required') if context.request.blank?
      context.fail!(error: 'No items in request') unless context.request['items']&.any?
    end
  end
end
