# frozen_string_literal: true

module Mirakl
  class IssueInvoicesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :mirakl_order_fulfilment, lock: :while_executing

    def perform(*_args) # rubocop:disable Metrics/MethodLength
      fees_invoices_count = Mirakl::Invoice.where(issued: false, invoice_type: :INVOICE).count
      credit_invoices_count = Mirakl::Invoice.where(issued: false, invoice_type: :CREDIT).count

      Mirakl::Invoice.where(issued: false).each do |invoice|
        result = Mirakl::IssueInvoiceInteractor.call(invoice_id: invoice.invoice_id).success?

        if result
          invoice.update(issued: true)
        else
          error_message = I18n.t('errors.issue_invoice_worker',
                                 class_name: self.class.name,
                                 invoice_id: invoice.invoice_id)
          Sentry.capture_message(error_message)
        end
      end

      notify_slack(credit_invoices_count, fees_invoices_count)
    end

    private

    def notify_slack(credit_invoices_count, fees_invoices_count)
      channel = Maisonette::Config.fetch('slack.vendor_invoices_feed')
      slack_message = "Successfully issued Mirakl invoices:
Credit: #{credit_invoices_count}

Fees: #{fees_invoices_count}"
      Maisonette::Slack.notify(channel: channel, username: 'Mirakl Invoices', payload: slack_message)
    end
  end
end
