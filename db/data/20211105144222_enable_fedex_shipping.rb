class EnableFedexShipping < ActiveRecord::Migration[6.0]

  EXTRA_SERVICE_LEVELS = [
    %w[FedExSmartPost SMART_POST],
    %w[FedEx FIRST_OVERNIGHT],
    %w[FedEx PRIORITY_OVERNIGHT],
    %w[FedEx STANDARD_OVERNIGHT],
    %w[FedEx FEDEX_GROUND],
    %w[FedEx FEDEX_2_DAY_AM],
    %w[FedEx FEDEX_2_DAY],
    %w[FedEx FEDEX_EXPRESS_SAVER],
  ].freeze

  def up
    Spree::ShippingCarrier.find_or_create_by(name: 'FedEx', code: 'FedEx', easypost_carrier_id: 'ca_1c4ee3e0c8ed419084bed4c34f0bf658')
    Spree::ShippingCarrier.find_or_create_by(name: 'FedEx Smart Post', code: 'FedExSmartPost', easypost_carrier_id: 'ca_9a81835a9390417c8bf2b3432aaefe9c')

    current_store = Spree::Store.first!
    current_service_levels = current_store.enabled_shipping_service_levels
    all_service_levels = current_service_levels + EXTRA_SERVICE_LEVELS
    current_store.update(enabled_shipping_service_levels: all_service_levels.sort)
  end
end
