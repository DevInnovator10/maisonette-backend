# frozen_string_literal: true

module Spree::Variant::OfferSettings
  def self.prepended(base)
    base.has_many :offer_settings, class_name: 'Spree::OfferSettings', dependent: :destroy
    base.ransackable_associations.push 'offer_settings'
  end

  def offer_settings_for_vendor(vendor)
    offer_settings.detect { |offer_settings_record| offer_settings_record.vendor == vendor }
  end
end
