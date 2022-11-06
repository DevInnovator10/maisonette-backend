# frozen_string_literal: true

module OrderManagement
  class PostReturnItemReceivedInteractor < ApplicationInteractor
    include Mirakl::ProcessReimbursements::Reimbursements

    before :validate_context
    before :prepare_context
    after :check_errors

    def call
      post_oms_request
    end

    private

    def post_oms_request
      reimbursement = find_or_create_reimbursement(context.refund, 'refund')
      payload = create_payload(reimbursement)
      context.response = OrderManagement::ClientInterface.post_return_item_received(payload)
      context.fail!(empty_response_error) unless context.response.success
    end

    def create_payload(reimb)
      ReturnedItemPresenter.new(mirakl_order_line.mirakl_order_line_id, reason, order_line_payload, reimb.id).payload
    end

    def mirakl_order_line
      context['mirakl_order_line']
    end

    def order_line_payload
      context['order_line_payload']
    end

    def reason
      Spree::RefundReason.find_by(mirakl_code: context['refund']['reason_code'])
    end

    def validate_context
      context.fail!(error: 'Mirakl order line required') if context['mirakl_order_line'].blank?
      context.fail!(error: 'Order line payload required') if context['order_line_payload'].blank?
    end

    def check_errors
      context.fail!(error: context.error_messages.join('; ')) if context.error_messages.any?
    end

    def prepare_context
      context.error_messages = []
    end

    def empty_response_error
      { error: I18n.t('order_management.post_oms_request', response: context.response) }
    end
  end
end
