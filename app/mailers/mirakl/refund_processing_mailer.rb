# frozen_string_literal: true

module Mirakl
  class RefundProcessingMailer < Spree::BaseMailer
    include MailerHelper
    include ActionView::Helpers::NumberHelper

    def refund_email(order_line_reimbursements, type, promo_code: nil)
      @order_line_reimbursements = fetch_order_line_reimbursements(order_line_reimbursements)
      @order = @order_line_reimbursements[0].line_item.order
      @return_fee = calculate_return_fee(@order_line_reimbursements)

      @introduction = { user_name: first_name,
                        heading: I18n.t("spree.mail.mirakl_#{type}.heading"),
                        image: I18n.t("spree.mail.mirakl_#{type}.image"),
                        content: content(type, promo_code) }

      @cta = { label: 'View Order',
               url: mail_url(order_url(@order)) }

      subject = mail_subject(I18n.t("spree.mail.mirakl_#{type}.subject", order_number: @order.number))
      mail(to: @order.email, from: Spree::Store.default.mail_from_address, subject: subject)
    end

    private

    def calculate_return_fee(order_line_reimbursements)
      order_line_reimbursements.flat_map do |reimb|
        rma = reimb.return_authorization
        rma.fees.return.pluck(:amount) if rma.present?
      end.compact.sum
    end

    def fetch_order_line_reimbursements(order_line_reimbursements)
      order_line_reimbursements.map do |reimb|
        reimb.is_a?(Mirakl::OrderLineReimbursement) ? reimb : Mirakl::OrderLineReimbursement.find(reimb)
      end
    end

    def first_name
      @order.user.blank? ? @order.bill_address.firstname : @order.user.first_name
    end

    def vendor_name
      @vendor_name ||= @order_line_reimbursements[0].order_line.order.shipment.mirakl_shop.name
    end

    def content(type, promo_code)
      key = vendor_name.match?(/maisonette/i) ? 'mais_vendor' : 'other_vendor'
      if promo_code
        I18n.t('spree.mail.mirakl_rejection.introduction_promo_code',
               vendor_prompt: I18n.t("spree.mail.mirakl_rejection.#{key}", vendor_name: vendor_name),
               order_number: @order.number,
               promo_code: promo_code)
      else
        I18n.t("spree.mail.mirakl_#{type}.introduction",
               vendor_prompt: I18n.t("spree.mail.mirakl_rejection.#{key}", vendor_name: vendor_name),
               order_number: @order.number,
               amount: number_to_currency(@order_line_reimbursements.sum(&:total)))
      end
    end
  end
end
