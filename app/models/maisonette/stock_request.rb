# frozen_string_literal: true

module Maisonette
  class StockRequest < ApplicationRecord
    class EmailAlreadyOnWaitlistException < StandardError; end

    belongs_to :variant, class_name: 'Spree::Variant', optional: false
    delegate :product, to: :variant

    validates :email,
              presence: true,
              'spree/email': true,
              uniqueness: {
                scope: [:variant_id, :state],
                message: 'is already on the waitlist for this product.',
                strict: EmailAlreadyOnWaitlistException
              }

    scope :requested, -> { where(state: 'requested') }
    scope :queued, -> { where(state: 'queued') }
    scope :notified, -> { where(state: 'notified') }

    scope :with_purchasable_variant, -> { joins(:variant).merge(Spree::Variant.purchasable) }

    state_machine :state, initial: :requested do
      event :queue do
        transition requested: :queued
      end

      event :notify do
        transition queued: :notified
      end

      after_transition to: :notified do |stock_request|
        Spree::UserMailer.back_in_stock(stock_request).deliver_later
        stock_request.update(sent_at: Time.current)
      end
    end
  end
end
