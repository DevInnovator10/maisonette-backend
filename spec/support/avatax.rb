# frozen_string_literal: true

class AvataxPreferences
  def self.set_preferences(address_validation: false, tax_calculation: false) # rubocop:disable Metrics/MethodLength
    Spree::Avatax::Config.reset

    Spree::Avatax::Config.configure do |config|
      # config.company_code = 'DEFAULT'
      # config.license_key = '12345'
      # config.account = '12345'

      config.refuse_checkout_address_validation_error = false
      config.log_to_stdout = false
      config.raise_exceptions = false
      config.log = false
      config.address_validation = address_validation
      config.tax_calculation = tax_calculation
      config.document_commit = false
      config.customer_can_validate = false

      config.address_validation_enabled_countries = ['United States', 'Canada']

      config.origin = {
        line1: '915 S Jackson St',
        line2: '',
        city: 'Montgomery',
        region: 'AL',
        postalCode: '36104',
        country: 'US'
      }.to_json
    end
  end
end

RSpec.configure do |config|
  config.before do |e|
    avatax_configuration = {
      address_validation: e.metadata[:avatax] == true || e.metadata.dig(:avatax, :address_validation) == true,
      tax_calculation: e.metadata[:avatax] == true || e.metadata.dig(:avatax, :tax_calculation) == true
    }

    AvataxPreferences.set_preferences(avatax_configuration)
  end
end
