# frozen_string_literal: true

module Spree::Product::Marketplace
  def self.prepended(base)
    base.delegate :display_price, :display_amount, :price, to: :cheapest_variant_price
  end

  def cheapest_variant_price
    @cheapest_variant_price ||= variants.purchasable.min_by(&:price)&.default_price || Spree::NullPrice.new
  end

  def total_on_hand(purchasable_only: false)
    return super() unless purchasable_only

    if any_variants_not_track_inventory?(purchasable_only: true)
      Float::INFINITY
    else
      stock_items.purchasable.sum(:count_on_hand)
    end
  end

  private

  def any_variants_not_track_inventory?(purchasable_only: false)
    return super() unless purchasable_only

    if purchasable_variants.loaded?
      purchasable_variants.any? { |v| !v.should_track_inventory? }
    else
      !Spree::Config.track_inventory_levels || purchasable_variants.where(track_inventory: false).exists?
    end
  end
end
