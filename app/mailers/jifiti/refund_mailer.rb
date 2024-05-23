# frozen_string_literal: true

module Jifiti
  class RefundMailer < Spree::BaseMailer
    include MailerHelper

    layout false

    def refund_not_shipped_order(order, mirakl_order_line_reimbursement = nil)
      @order = order
      @mirakl_order_line_reimbursement = mirakl_order_line_reimbursement

      mail(
        to: Maisonette::Config.fetch('jifiti.order_email'),
        bcc: Maisonette::Config.fetch('jifiti.mais_order_email'),
        from: Spree::Store.default.mail_from_address,
        subject: I18n.t('spree.mail.refund_jifiti_not_shipped_order.subject', order_number: order.number)
      )
    end

    def error_refund_shipped_order(order)
      @order = order

      mail(
        to: Maisonette::Config.fetch('jifiti.mais_order_email'),
        from: Spree::Store.default.mail_from_address,
        subject: I18n.t('spree.mail.error_refund_jifiti_shipped_order.subject', order_number: order.number)
      )
    end
  end
end
