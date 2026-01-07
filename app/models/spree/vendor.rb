# frozen_string_literal: true

module Spree
  class Vendor < ApplicationRecord
    validates :avalara_code, uniqueness: true
    belongs_to :mirakl_shop, class_name: 'Mirakl::Shop', optional: true
    has_one :stock_location, class_name: 'Spree::StockLocation', dependent: :nullify
    has_many :prices, class_name: 'Spree::Price', dependent: :destroy
    has_many :line_items, class_name: 'Spree::LineItem', dependent: :nullify
    has_many :offer_settings, class_name: 'Spree::OfferSettings', dependent: :destroy

    validates :name, presence: true, uniqueness: true

    delegate :country_iso, :domestic_override, to: :stock_location, allow_nil: true

    def self.default
      Spree::Vendor.find_or_create_by(name: 'Maisonette') { |v| v.avalara_code = v.name }
    end

    def to_s
      name
    end

    def estimated_giftwrap_price
      (giftwrap_price || Maisonette::Config.fetch('default_giftwrap_price')).to_f
    end
  end
end
