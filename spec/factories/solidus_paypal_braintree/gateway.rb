# frozen_string_literal: true

FactoryBot.define do
  factory :solidus_paypal_braintree_gateway, class: SolidusPaypalBraintree::Gateway do
    name { 'Braintree' }
    auto_capture { true }
    preferences do
      {

        environment: 'sandbox',
        merchant_id: Maisonette::Config.fetch('braintree.merchant_id'),
        public_key: Maisonette::Config.fetch('braintree.public_key'),
        private_key: Maisonette::Config.fetch('braintree.private_key')
      }
    end
  end
end
