# frozen_string_literal: true

# Spree requires for testing.
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/factories'
require 'spree/testing_support/preferences'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/flash'
require 'spree/testing_support/url_helpers'
require 'spree/testing_support/order_walkthrough'
require 'spree/testing_support/capybara_ext'
require 'spree/api/testing_support/caching'
require 'spree/api/testing_support/helpers'
require 'spree/api/testing_support/setup'
require 'spree/api/acceptance_testing_support/helpers'
require 'solidus_sale_prices/testing_support/factories'

RSpec.configure do |config|
  config.include Spree::TestingSupport::Preferences
  config.include Spree::TestingSupport::UrlHelpers, type: :integration
  config.include Spree::TestingSupport::ControllerRequests, type: :controller
  config.include Spree::TestingSupport::Flash
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Spree::Api::TestingSupport::Helpers, type: :controller
  config.include Spree::Api::TestingSupport::Helpers, type: :acceptance
  config.include Spree::Api::TestingSupport::Helpers, type: :request
  config.include Spree::Api::AcceptanceTestingSupport::Helpers, type: :acceptance
  config.extend Spree::Api::TestingSupport::Setup, type: :controller
end
