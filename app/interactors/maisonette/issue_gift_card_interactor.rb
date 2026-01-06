# frozen_string_literal: true

module Maisonette
  class IssueGiftCardInteractor < ApplicationInteractor
    before :validate_context

    def call
      context.gift_card.update!(
        original_amount: context.original_amount,
        redeemable: context.redeemable || true,
        currency: context.currency,
        state: context.state || 'issued'
      )
    rescue ActiveRecord::RecordInvalid => e
      context.fail!(error: e.message)
    end

    private

    def validate_context
      context.fail!(errors: 'No gift card') if context.gift_card.nil?
    end
  end
end
