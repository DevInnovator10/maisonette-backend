# frozen_string_literal: true

module Mirakl
  module Invoices
    class ReSubmitFeesInvoiceInteractor < ApplicationInteractor
      helper_methods :mirakl_shop

      def call
        Mirakl::Invoice.where(mirakl_shop: mirakl_shop, issued: false).INVOICE.destroy_all

        Mirakl::ShopFeesInvoiceWorker.new.perform(shop_ids: [[mirakl_shop.shop_id, mirakl_shop.id]])
      rescue StandardError => e
        fail_interaction(e)
      end

      private

      def mirakl_shop
        @mirakl_shop ||= context.mirakl_shop
      end

      def fail_interaction(exception)
        error_message = I18n.t('errors.mirakl_fee_invoice_interactor',
                               class_name: self.class.name,
                               mirakl_shop: mirakl_shop.name)
        Sentry.capture_exception_with_message(exception, message: error_message)
        context.fail!(error: exception)
      end
    end
  end
end
