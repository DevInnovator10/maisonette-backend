# frozen_string_literal: true

module Spree::Variant::OrderManagement
  def self.prepended(base)
    base.after_commit :mark_offer_settings_out_of_sync!
  end

  def mark_offer_settings_out_of_sync!
    return unless offer_settings.any?

    offer_settings.each(&:mark_out_of_sync!)
  end
end
