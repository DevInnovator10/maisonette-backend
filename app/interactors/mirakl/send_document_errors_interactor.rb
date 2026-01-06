# frozen_string_literal: true

module Mirakl
  class SendDocumentErrorsInteractor < ApplicationInteractor
    # Input:
    # - shop_id: destination Mirakl shop
    # - order_ids: mirakl orders
    # - documents_time: starting date/hour for documents processing
    def call
      shop = Mirakl::Shop.find context.shop_id
      args = prepare_mailer_args(shop)
      Mirakl::ShopDocumentErrorsMailer.with(args).shop_document_errors_email.deliver_now!
      mirakl_orders.update_all(bulk_document_error_sent: true) # rubocop:disable Rails/SkipsModelValidations
    end

    private

    def mirakl_orders
      @mirakl_orders ||= Mirakl::Order.where(id: context.order_ids)
    end

    def prepare_mailer_args(shop)
      {
        recipient: shop.email,
        vendor_name: shop.name,

        orders: mirakl_orders.pluck(:logistic_order_id),
        documents_time: context.documents_time,
      }
    end
  end
end
