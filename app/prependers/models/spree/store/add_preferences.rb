# frozen_string_literal: true

module Spree::Store::AddPreferences
    def self.prepended(base)
    base.include Spree::Preferences::Persistable

    base.preference :customer_return_fee_enabled, :boolean, default: false
    base.preference :customer_return_fee_amount, :decimal, default: 5
    base.preference :customer_return_fee_launch_date, :string
  end
end
