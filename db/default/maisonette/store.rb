# frozen_string_literal: true

store_attrs = I18n.t('seeds.stores.maisonette')
store = Spree::Store.find_or_initialize_by(code: store_attrs[:code]) do |st|
  st.assign_attributes store_attrs
end
store.build_braintree_configuration(
  credit_card: true,
  paypal: true,
  apple_pay: true
)

shipping_carrier_services = [
  %w[DHLExpress ExpressWorldwideNonDoc],
  %w[UPS 2ndDayAir],
  %w[UPS 3DaySelect],
  %w[UPS Expedited],
  %w[UPS Ground],
  %w[UPS NextDayAir],
  %w[UPS NextDayAirSaver],
  %w[UPS UPSSaver],
  %w[UPS UPSStandard],
  %w[UPSSurePost SurePostOver1Lb],
  %w[UPSSurePost SurePostUnder1Lb],
  %w[USPS First],
  %w[USPS ParcelSelect],
  %w[USPS Priority],
  %w[FedExSmartPost SMART_POST],
  %w[FedEx PRIORITY_OVERNIGHT],
  %w[FedEx STANDARD_OVERNIGHT],
  %w[FedEx FEDEX_GROUND],
  %w[FedEx FEDEX_2_DAY],
  %w[FedEx FEDEX_EXPRESS_SAVER],
  %w[FedEx GROUND_HOME_DELIVERY],
]
store.enabled_shipping_service_levels = shipping_carrier_services.sort

notify_if_saved(store)
