# frozen_string_literal: true

module PaymentHelper
  def order_payment_label(order, join_by = '<br />')
    order.payments.valid.map { |payment| payment_label(payment) }.reject(&:blank?).uniq.join(join_by)
  end

  def payment_label(payment, join_by = ' ')
    [source_name(payment), payment_description(payment)].reject(&:blank?).join(join_by)
  end

  def source_name(payment)
    return '' if !payment.source || payment.source.is_a?(Spree::CreditCard)
    return 'Store Credit' if payment.source.is_a? Spree::StoreCredit

    payment.source.payment_type.underscore.humanize
  end

  def payment_description(payment)
    return '' unless payment.source

    multiple_payments = payment.order.payments.valid.size > 1

    if source_name(payment).include?('Pay pal')
      paypal_email_source_description(payment, multiple_payments)
    elsif payment.source_type == 'SolidusPaypalBraintree::Source'
      credit_card_source_description(payment, multiple_payments)
    elsif payment.source_type == 'Spree::StoreCredit'
      store_credit_source_description(payment, multiple_payments)
    end
  end

  private

  def paypal_email_source_description(payment, multiple_payments)
    str = payment.source.email
    str += " (#{payment.display_amount})" if multiple_payments && str
    str
  end

  def credit_card_source_description(payment, multiple_payments)
    if payment.source.card_type.nil? && payment.source.last_digits.nil?
      "(#{payment.display_amount})" if multiple_payments
    else
      str = [payment.source.card_type.upcase, "Ending in #{payment.source.last_digits}"].reject(&:blank?).join(', ')
      str += " (#{payment.display_amount})" if multiple_payments
      str
    end
  end

  def store_credit_source_description(payment, multiple_payments)
    if multiple_payments
      "(#{Spree::Money.new(payment.order.total_applicable_store_credit, currency: payment.order.currency)})"
    else
      ''
    end
  end
end
