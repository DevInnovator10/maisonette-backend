# frozen_string_literal: true

module Spree::Order::ValidateAddressesZone
  def ensure_available_shipping_rates
    validate_addresses_zone

    super
  end

  def validate_addresses_zone
    unless shipping_address_zone_valid?
      errors.add :base, :shipping_address_inclusion
      throw :halt
    end

    unless billing_address_zone_valid? # rubocop:disable Style/GuardClause
      errors.add :base, :billing_address_inclusion
      throw :halt
    end
  end

  private

  def shipping_address_zone_valid?
    address_zone_valid? shipping_address, Spree::Zone::SHIPPING_ZONE_NAME
  end

  def billing_address_zone_valid?
    address_zone_valid? billing_address, Spree::Zone::BILLING_ZONE_NAME
  end

  def address_zone_valid?(address, zone_name)
    zone = Spree::Zone.where(Spree::Zone.arel_table[:zone_members_count].gt(0)).find_by(name: zone_name)

    return true unless address && zone

    zone.include? address
  end
end
