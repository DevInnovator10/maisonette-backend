# frozen_string_literal: true

require_relative 'default/maisonette/store'
require_relative 'default/maisonette/feature_flags'

%w[
  reimbursement_types
  store_credit
  countries
  states
  zones
  shipping_category
  shipping_carrier
  shipping_method
  roles
  tax_category_and_rate
].each do |seed|
  puts "Loading seed file: #{seed}"
  require_relative "default/spree/#{seed}"
end

SolidusAvataxCertified::Engine.load_seed if defined?(SolidusAvataxCertified::Engine)

SolidusAvataxCertified::Seeder.seed_use_codes!
