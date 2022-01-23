# frozen_string_literal: true

module Spree
  class GiftCard < ApplicationRecord
    belongs_to :promotion_code, dependent: :destroy, optional: false
    belongs_to :line_item, optional: true
    has_many :gift_card_transactions, dependent: :destroy
    before_save :recalculate_balance

    validates :original_amount, numericality: { greater_than: 0.0, allow_nil: true }
    validates :state, exclusion: { in: ['issued'] }, if: -> { original_amount.nil? }

    delegate :value, to: :promotion_code

    enum state: { allocated: 'allocated', issued: 'issued' }

    scope :active, lambda {
      table = arel_table
      time = Time.current
      where(table[:starts_at].eq(nil).or(table[:starts_at].lt(time)))
        .where(table[:expires_at].eq(nil).or(table[:expires_at].gt(time)))
    }

    def send_email
      return unless send_email_at.nil? || send_email_at <= DateTime.now.in_time_zone

      Spree::GiftCardMailer.send_gift_card(self).deliver_later
      Spree::GiftCardMailer.send_confirmation(self).deliver_later
    end

    def details
      {
        recipient_email: recipient_email,
        recipient_name: recipient_name,
        purchaser_name: purchaser_name,
        gift_message: gift_message,
        send_email_at: send_email_at,
        formatted_send_email_at: formatted_send_email_at
      }
    end

    def active?
      started? && not_expired?
    end

    def started?
      starts_at.nil? || starts_at < Time.current
    end

    def expired?
      expires_at.present? && expires_at < Time.current
    end

    def not_expired?
      !expired?
    end

    def compute_amount(order)
      return 0 if !redeemable || !active? || order.item_total.zero?

      source_adjustment = order.gift_card_adjustments.find_by(source_id: id)
      if source_adjustment
        amount_for_this_adjustment(order, source_adjustment)
      else
        amount = [balance, order.total].min
        amount * -1
      end
    end

    def redeem!(amount)
      redemption_amount = [balance, amount].min

      gift_card_transactions.create!(
        action: Spree::GiftCardTransaction::REDEMPTION,
        amount: redemption_amount
      )
    end

    private

    def balance=(amount)
      self[:balance] = Spree::Money.new(amount)
    end

    def recalculate_balance
      result = original_amount.to_f + gift_card_transactions.redeemed.sum(&:amount)
      self.balance = result
    end

    def amount_for_this_adjustment(order, source_adjustment)
      if order.total == order.gift_card_adjustments_total.abs
        source_adjustment.amount
      else
        gift_card_total_no_source = order.gift_card_adjustments_total - source_adjustment.amount

        [balance, order.total + gift_card_total_no_source].min * -1
      end
    end

    def formatted_send_email_at
      send_email_at&.strftime('%-m/%-d/%y')
    end
  end
end
