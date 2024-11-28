# frozen_string_literal: true

module Braintree
  class ImportDisputesWorker
    include Sidekiq::Worker

    sidekiq_options lock: :while_executing, retry: false

    def perform(*_args)
      context = Braintree::ImportDisputesInteractor.call
      if context.failure? && context.message == 'missing payments' # rubocop:disable Style/GuardClause
        Sentry.capture_exception_with_message(message: context.message, params: context.missing_payments)
      end
    end
  end
end
