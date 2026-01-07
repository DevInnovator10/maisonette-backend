# frozen_string_literal: true

module Spree::Shipment::Giftwrap
  def self.prepended(base)
    base.has_one :giftwrap, class_name: 'Maisonette::Giftwrap', dependent: :nullify
    base.delegate :giftwrap_service?, :estimated_giftwrap_price, to: :vendor, allow_nil: true
    base.accepts_nested_attributes_for :giftwrap, allow_destroy: true

    base.before_destroy :update_giftwrap_and_destroy_adjustments, prepend: true

    base.extend Spree::DisplayMoney
    base.money_methods :estimated_giftwrap_price
  end

  def giftwrappable?
    inventory_units.presence&.all? do |iu|
      iu.giftwrappable?
    end
  end

  def giftwrapped?
    giftwrap.present?
  end
  alias has_giftwrap? giftwrapped?

  private

  def update_giftwrap_and_destroy_adjustments
    giftwrap&.tap do |giftwrap|
      giftwrap.adjustments.destroy_all
    end
  end
end
