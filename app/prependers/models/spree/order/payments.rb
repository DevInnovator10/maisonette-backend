# frozen_string_literal: true

module Spree::Order::Payments
  def self.prepended(base)
    base.remove_method :add_store_credit_payments
  end

  def add_store_credit_payments
    recalculate_payments
  end

  def recalculate_payments # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
    payments.store_credits.checkout.each(&:invalidate!)

    # this can happen when multiple payments are present, auto_capture is
    # turned off, and one of the payments fails when the user tries to
    # complete the order, which sends the order back to the 'payment' state.

    authorized_total = payments.pending.sum(:amount)

    remaining_total = outstanding_balance - authorized_total

    if matching_store_credits.any?
      payment_method = Spree::PaymentMethod::StoreCredit.first

      matching_store_credits.order_by_priority.each do |credit|
        break if remaining_total.zero?
        next if credit.amount_remaining.zero?

        amount_to_take = [credit.amount_remaining, remaining_total].min
        payments.create!(source: credit,
                         payment_method: payment_method,
                         amount: amount_to_take,
                         state: 'checkout',
                         response_code: credit.generate_authorization_code)
        remaining_total -= amount_to_take
      end
    end

    other_payments = payments.checkout.not_store_credits
    if remaining_total.zero?
      other_payments.each(&:invalidate!)
    elsif other_payments.size == 1
      other_payments.first.update!(amount: remaining_total)
    end

    payments.reset

    return if payments.store_credits.checkout.empty? && !store_credits_available
    return unless payments.where(state: %w[checkout pending completed]).sum(:amount) != total

    errors.add(:base, I18n.t('spree.store_credit.errors.unable_to_fund'))
    false
  end

  private

  def store_credits_available
    return false if user.nil?

    user.available_store_credit_total(currency: currency).positive?
  end

  def matching_store_credits
    return [] unless user

    @matching_store_credits ||= if use_store_credits?
                                  user.store_credits.where(currency: currency)
                                else
                                  []
                                end
  end
end
