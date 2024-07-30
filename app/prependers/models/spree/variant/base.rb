# frozen_string_literal: true

module Spree::Variant::Base
  def self.prepended(base)
    base.attr_accessor :skip_marketplace_sku_not_change_validation

    base.has_many :stock_requests, dependent: :nullify, class_name: 'Maisonette::StockRequest'
    base.delegate :brand, :brand_description, :promotionable, :property, to: :product
    base.validate :marketplace_sku_not_change, on: :update, unless: :skip_marketplace_sku_not_change_validation
    base.has_many :active_sale_prices,
                  -> { merge(Spree::SalePrice.active) },
                  through: :prices,
                  source: :sale_prices,
                  class_name: 'Spree::SalePrice'
  end

  def to_s
    return "#{name} - Master" if is_master

    "#{name} - #{options_text}"
  end

  def discontinued?
    return true if product.discontinued?

    !!available_until && available_until <= Time.current
  end

  def available?
    !discontinued? && (!!available_on && available_on <= Time.current)
  end

  def cost_price=(price)
    Rails.logger.warn 'You should not persist cost_price on variant. Consider saving it on Spree::OfferSettings'
    super
  end

  def wait_list
    stock_requests.requested
  end

  def queue_wait_list
    wait_list.update_all(state: :queued) # rubocop:disable Rails/SkipsModelValidations
  end

  def really_update_marketplace_sku!(new_marketplace_sku)
    self.skip_marketplace_sku_not_change_validation = true

    update!(marketplace_sku: new_marketplace_sku)
  end

  private

  def marketplace_sku_not_change
    return if is_master?
    return if marketplace_sku_was.nil?
    return unless marketplace_sku_changed?
    return unless offer_settings.count > 1

    errors.add(:marketplace_sku, I18n.t('errors.spree.variant.marketplace_sku_change_not_allow'))
  end
end
