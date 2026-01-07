# frozen_string_literal: true

module Spree::LineItem::Marketplace
    def self.prepended(base) # rubocop:disable Metrics/AbcSize
    base.belongs_to :vendor, optional: false
    base.has_one :offer_settings, (lambda do |line_item|
      joins(:vendor).where(spree_vendors: { id: line_item.vendor_id }).with_discarded
    end), through: :variant

    base.validates :vendor, presence: true
    base.validate :vendor_should_have_price
    base.validates :duty_fees, numericality: { allow_nil: true, greater_than_or_equal_to: 0.0 }
    base.delegate :country_iso, to: :vendor
    base.delegate :internal_package_dimensions, to: :offer_settings

    base.before_validation :set_final_sale, if: :current_price_for_vendor, unless: -> { order&.complete? }
    base.before_validation :set_original_price, if: -> { current_price_for_vendor && price_changed? }
  end

  def vendor_should_have_price
    return if variant.nil? || order.complete?

    errors.add(:vendor, 'there are no price for this vendor') if variant.prices.where(vendor: vendor).none?
  end

  def sufficient_stock?
    return false if vendor.stock_location.nil?

    stock_quantifier.can_supply? quantity
  end

  def backorder_date
    stock_quantifier.stock_items.minimum(:backorder_date)
  end

  def stock_quantifier
    Spree::Stock::Quantifier.new(variant, vendor.stock_location)
  end

  def on_sale?
    original_price > price
  end

  def fetch_cost_price
    current_price_for_vendor&.active_sale&.cost_price || offer_settings&.cost_price
  end

  def fetch_our_liability_amount
    current_price_for_vendor&.active_sale&.our_liability_amount
  end

  def set_pricing_attributes(force_update: false) # rubocop:disable Metrics/LineLength, Metrics/PerceivedComplexity, Naming/AccessorMethodName
    self.cost_price = fetch_cost_price if cost_price.nil? || force_update
    self.mark_down_our_liability = fetch_our_liability_amount if mark_down_our_liability.nil? || force_update
    set_money_price if price.nil? || force_update
    self.duty_fees = offer_settings&.duty_fees if duty_fees.nil? || force_update
    true
  end

  private

  def set_money_price
    money = if monogram
              Spree::Money.new(current_price_for_vendor.price + monogram.price,
                               currency: current_price_for_vendor.currency)
            else
              current_price_for_vendor&.money
            end

    self.money_price = money
  end

  def current_price_for_vendor
    @current_price_for_vendor ||= variant&.price_for_vendor(vendor, as_money: false)
  end

  def set_original_price
    return if %w[complete canceled].include? order&.state

    self.original_price = current_price_for_vendor.original_price
  end

  def set_final_sale
    self.final_sale = current_price_for_vendor.reload.final_sale? || monogram.present?
  end
end
