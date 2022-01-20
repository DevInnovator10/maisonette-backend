# frozen_string_literal: true

Spree::Avatax::Config.configure do |config|
  config.refuse_checkout_address_validation_error = false
  config.log_to_stdout = Maisonette::Config.fetch('lograge.enabled')
  config.raise_exceptions = false
  config.log = true
  config.address_validation = false
  config.tax_calculation = true
  config.document_commit = true
  config.customer_can_validate = true

  config.address_validation_enabled_countries = ['United States', 'Canada']

  config.origin = {
    line1: '380 Degraw Street',
    line2: '',
    city: 'Brooklyn',
    region: 'NY',
    postalCode: '11231',
    country: 'US'
  }.to_json
end
