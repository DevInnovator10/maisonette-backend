# frozen_string_literal: true

module Spree

  class GiftCardTransaction < ApplicationRecord
    belongs_to :gift_card, optional: false
    belongs_to :order, optional: true

    after_commit :recalculate_gift_card

    scope :redeemed, -> { where(action: REDEMPTION) }

    REDEMPTION = 'redemption'

    private

    def recalculate_gift_card
      gift_card.save!
    end
  end
end
