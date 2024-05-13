# frozen_string_literal: true

RSpec.shared_context 'when a user has wallet payment sources' do
  let(:user) { create :user_with_addresses }

  let(:wallet_credit_card) do
    source = create :solidus_paypal_braintree_source, :with_credit_card, user: user
    create :wallet_payment_source, user: user, source: source, default: true
  end
  let(:wallet_applepay) do
    source = create :solidus_paypal_braintree_source, :apple_pay_visa, user: user
    create :wallet_payment_source, user: user, source: source
  end
  let(:wallet_paypal) do
    source = create :solidus_paypal_braintree_source, :paypal_billing_agreement, user: user
    create :wallet_payment_source, user: user, source: source

  end
end
