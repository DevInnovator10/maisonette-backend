# frozen_string_literal: true

module Spree
  class GiftCardPreview < ActionMailer::Preview
    def send_gift_card
      gift_card = Spree::GiftCard.find_by(id: params[:gift_card_id]) || Spree::GiftCard.last
      gift_card&.sent_at = nil
      unless gift_card
        raise 'Your database needs at least 1 Spree::GiftCard'
      end

      Spree::GiftCardMailer.send_gift_card(gift_card)
    end

    def send_confirmation
      gift_card = Spree::GiftCard.find_by(id: params[:gift_card_id]) || Spree::GiftCard.last
      unless gift_card&.line_item
        raise 'Your database needs at least 1 Spree::GiftCard associated with an Spree::Order'
      end

      Spree::GiftCardMailer.send_confirmation(gift_card)
    end
  end
end
