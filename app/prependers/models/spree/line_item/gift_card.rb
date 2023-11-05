# frozen_string_literal: true

module Spree::LineItem::GiftCard
  def self.prepended(base)
    base.has_many :gift_cards, class_name: 'Spree::GiftCard', dependent: :destroy
    base.delegate :gift_card?, :gift_card, to: :product
  end

  def options=(options = {})
    options.delete(:gift_card_details)

    super(options)
  end
end
