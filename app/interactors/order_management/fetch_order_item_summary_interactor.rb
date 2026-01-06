# frozen_string_literal: true

module OrderManagement
  class FetchOrderItemSummaryInteractor < ApplicationInteractor
    before :validate_context

    def call
      query_order_item_summaries
      persit_order_item_summaries
      context.sales_order.reload.forward_complete!
    end

    private

    def validate_context
      context.fail!(error: "SalesOrder required in #{self.class.name}") if context.sales_order.blank?
    end

    def query_order_item_summaries
      context.query_response = OrderManagement::ClientInterface.query_object_ids_by(
        item_summaries_external_ids,
        OrderItemSummary.order_management_object_name
      )
      context.fail!(empty_response_error) if context.query_response.items.empty?
    end

    def item_summaries_external_ids
      context.sales_order.order_item_summaries.map(&:external_id)
    end

    def empty_response_error
      { error: I18n.t('order_management.order_item_summary_empty', response: context.query_response.response) }
    end

    def persit_order_item_summaries
      context.query_response.items.each do |item|
        item_summary = GlobalID::Locator.locate(item.External_Id__c)
        context.fail!(unable_to_locate_item_summary_error(item)) unless item_summary
        item_summary.update!(order_management_ref: item.Id)
      end
    end

    def unable_to_locate_item_summary_error(item_summary)
      { error: I18n.t('order_management.unable_to_locate_item_summary', item_summary: item_summary) }
    end
  end
end
