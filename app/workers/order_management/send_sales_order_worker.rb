# frozen_string_literal: true

module OrderManagement
  class SendSalesOrderWorker
    include Sidekiq::Worker

    sidekiq_options lock: :while_executing, conflict_strategy: :reject, retry: 0, queue: 'order_management'

    def perform(sales_order_id)
      result = OrderManagement::SendSalesOrderInteractor.call(
        sales_order: OrderManagement::SalesOrder.find(sales_order_id)
      )
      log_error(result, sales_order_id: sales_order_id, interactor: result) if result.failure?
    rescue StandardError => e
      log_error(e)
      raise e
    end

    private

    def log_error(exception, extra = {})
      if exception.is_a?(Interactor::Context)
        Rails.logger.error(exception.error)
        Sentry.capture_message(exception.error, extra: extra)
      else
        message = I18n.t('order_management.something_went_wrong', exception: exception.message)
        Rails.logger.error(message)
        Sentry.capture_exception_with_message(exception, extra: { message: message }.merge(extra))
      end
    end
  end
end
