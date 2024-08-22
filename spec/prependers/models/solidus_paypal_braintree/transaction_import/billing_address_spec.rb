# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolidusPaypalBraintree::TransactionImport::BillingAddress do
  let(:described_class) { super().parent }

  describe '#import!', :vcr do
    describe 'order addresses updating' do
      subject(:described_method) { transaction_import.import! 'confirm' }

      let(:order) { create :order_with_line_items }
      let(:shipping_address) do
        SolidusPaypalBraintree::TransactionAddress.new(

          country_code: order.shipping_address.country.iso,
          last_name: 'fake shipping address last name',
          first_name: 'fake shipping address first name',
          city: 'fake shipping address city',
          zip: 'fake shipping address zip',
          state_code: order.shipping_address.state.abbr,
          address_line_1: 'fake shipping address address line 1',
          address_line_2: 'fake shipping address address line 2'
        )
      end
      let(:billing_address_country) { create :country, iso: 'IT' }
      let(:billing_address_state) { create :state, country: billing_address_country, name: 'Taranto', abbr: 'TA' }
      let(:billing_address) do
        SolidusPaypalBraintree::TransactionAddress.new(
          country_code: billing_address_country.iso,
          last_name: 'fake billing address last name',
          first_name: 'fake billing address first name',
          city: 'fake billing address city',
          zip: 'fake billing address zip',
          state_code: billing_address_state.abbr,
          address_line_1: 'fake billing address address line 1',
          address_line_2: 'fake billing address address line 2'
        )
      end
      let(:payment_method) { create :solidus_paypal_braintree_gateway }
      let(:payment_type) { SolidusPaypalBraintree::Source::PAYPAL }
      let(:transaction) do
        SolidusPaypalBraintree::Transaction.new(
          nonce: Braintree::Test::Nonce::PayPalBillingAgreement,
          payment_method: payment_method,
          payment_type: payment_type,
          email: 'test@example.com',
          phone: '0123456789',
          shipping_address: shipping_address,
          billing_address: billing_address
        )
      end
      let(:transaction_import) { described_class.new order, transaction }
      let(:matching_attributes) { %w[firstname lastname address1 address2 city zipcode state_id country_id] }

      before { described_method }

      context 'when the transaction has both shipping address and billing address' do
        it 'updates the order shipping address with the transaction shipping address data' do
          expect(order.shipping_address.attributes.slice(*matching_attributes, 'phone')).to eq(
            shipping_address.to_spree_address.attributes.slice(*matching_attributes).merge('phone' => transaction.phone)
          )
        end

        it 'updates the order billing address with the transaction billing address data' do
          expect(order.billing_address.attributes.slice(*matching_attributes, 'phone')).to eq(
            billing_address.to_spree_address.attributes.slice(*matching_attributes).merge('phone' => transaction.phone)
          )
        end
      end

      context 'when the transaction has shipping address only' do
        let(:transaction) do
          SolidusPaypalBraintree::Transaction.new(
            nonce: Braintree::Test::Nonce::PayPalBillingAgreement,
            payment_method: payment_method,
            payment_type: payment_type,
            email: 'test@example.com',
            phone: '1234567890',
            shipping_address: shipping_address
          )
        end

        it 'updates the order shipping address with the transaction shipping address data' do
          expect(order.shipping_address.attributes.slice(*matching_attributes, 'phone')).to eq(
            shipping_address.to_spree_address.attributes.slice(*matching_attributes).merge('phone' => transaction.phone)
          )
        end

        it 'updates the order billing address with the transaction shipping address data' do
          expect(order.billing_address.attributes.slice(*matching_attributes, 'phone')).to eq(
            shipping_address.to_spree_address.attributes.slice(*matching_attributes).merge('phone' => transaction.phone)
          )
        end
      end
    end
  end
end
