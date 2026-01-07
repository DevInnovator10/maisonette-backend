# frozen_string_literal: true

module Spree::OrderContents::GiftCard
  class GiftCardDateFormatError < StandardError; end

  def add(variant, quantity = 1, options = {})
    line_item = super(variant, quantity, options)

    return line_item unless line_item.gift_card?

    quantity.to_i.times { allocate_gift_card(line_item, options[:gift_card_details] || {}) }

    line_item
  end

  def remove(variant, quantity = 1, options = {})
    line_item = super(variant, quantity, options)
    remove_gift_cards(line_item, quantity)
    line_item
  end

  private

  def allocate_gift_card(line_item, gift_card_details = {})
    Maisonette::AllocateGiftCardInteractor.call!(
      order: order,
      line_item_id: line_item.id,
      recipient_name: gift_card_details['recipient_name'],
      recipient_email: gift_card_details['recipient_email'],
      purchaser_name: gift_card_details['purchaser_name'],
      gift_message: gift_card_details['gift_message'],
      send_email_at: format_date(gift_card_details['send_email_at'])
    )
  end

  def remove_gift_cards(line_item, quantity)
    return unless line_item.gift_card?

    line_item.gift_cards.order(:created_at).last(quantity).each(&:destroy!)
  end

  def format_date(date)
    return date if date.acts_like?(:date) || date.acts_like?(:time)
    return Time.zone.today if date.nil?

    begin
      Date.parse(date)
    rescue ArgumentError
      raise GiftCardDateFormatError
    end
  end
end
