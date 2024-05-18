# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Braintree::FillCustomerInfoInteractor, :vcr do
  let(:gateway) { create(:solidus_paypal_braintree_gateway) }
  let(:solidus_paypal_braintree_source) do
    create(:solidus_paypal_braintree_source, :transactable_visa, payment_method: gateway, payments: [payment])
  end
  let(:solidus_paypal_braintree_customer) do
    create(
      :solidus_paypal_braintree_customer,
      sources: [solidus_paypal_braintree_source],
      braintree_customer_id: braintree_customer.id,
      filled: false
    )
  end
  let(:order) { create(:order, user: user) }
  let(:user) { create(:user, email: 'john.doe@example.com') }
  let(:payment) { create(:solidus_paypal_braintree_credit_card_payment, order: order) }
  let(:braintree_gateway) { gateway.braintree }
  let(:braintree_customer) do
    create_result = braintree_gateway.customer.create
    create_result.customer
  end

  before do
    solidus_paypal_braintree_customer
  end

  describe '#call' do
    subject(:call) { described_class.call(source_id: solidus_paypal_braintree_source.id) }

    it 'update the braintree customer fields' do # rubocop:disable RSpec/MultipleExpectations
      expect(braintree_customer.first_name).to be_blank
      expect(braintree_customer.last_name).to be_blank
      expect(braintree_customer.email).to be_blank
      expect(braintree_customer.phone).to be_blank

      expect(call).to be_a_success

      updated_braintree_customer = braintree_gateway.customer.find(braintree_customer.id)

      expect(updated_braintree_customer.first_name).to eq payment.order.billing_address.first_name
      expect(updated_braintree_customer.last_name).to eq payment.order.billing_address.last_name
      expect(updated_braintree_customer.email).to eq payment.order.email
      expect(updated_braintree_customer.phone).to eq payment.order.billing_address.phone
    end

    it 'marks the braintree customer as filled' do
      expect(solidus_paypal_braintree_customer).not_to be_filled

      expect(call).to be_a_success

      expect(solidus_paypal_braintree_customer.reload).to be_filled
    end

    context 'when braintree customer update fails' do
      it 'fails' do
        order.update_column(:email, 'invalid field')

        expect(call).to be_a_failure
        expect(call.message).to eq 'Email is an invalid format.'
      end
    end

    context 'when braintree customer fields are already present' do
      before do
        allow(Braintree::Gateway).to receive(:new).and_return(braintree_gateway)
        allow(braintree_gateway).to receive(:customer).and_return(customer)
        allow(customer).to receive(:update)
      end

      let(:customer) { class_double('Braintree::Customer', find: braintree_customer) }
      let(:braintree_customer) do
        create_result = braintree_gateway.customer.create(
          email: 'fake-user@maisonette.com',
          first_name: 'John',
          last_name: 'Doe',
          phone: '3338888888'
        )
        create_result.customer
      end

      it 'skips the customer update' do
        expect(call).to be_a_success

        expect(customer).not_to have_received(:update)
      end

      context 'when braintree customer is not found' do
        before { allow(customer).to receive(:find).and_raise(Braintree::NotFoundError) }

        it 'fails' do
          expect(call).to be_a_failure
          expect(call.message).to eq 'Braintree user not found'
        end
      end
    end

    context 'when source has not payments' do
      let(:solidus_paypal_braintree_source) do
        create(:solidus_paypal_braintree_source, :transactable_visa, payment_method: gateway, payments: [])
      end
      let(:csv_body) do
        "source_id,order_email,order_billing_first_name,order_billing_last_name,order_billing_phone\n
        #{solidus_paypal_braintree_source.id},export@email.com,export_first_name,export_last_name,123"
      end

      before do
        allow(Maisonette::Config).to receive(:fetch).with('aws.private_bucket').and_return('private_bucket')
        file_name = Braintree::FillCustomerInfoInteractor::EXPORT_FILE_NAME
        allow(S3).to receive(:get).with("legacy/#{file_name}", bucket: 'private_bucket') { csv_body }
      end

      it 'update the braintree customer fields' do # rubocop:disable RSpec/MultipleExpectations
        expect(braintree_customer.first_name).to be_blank
        expect(braintree_customer.last_name).to be_blank
        expect(braintree_customer.email).to be_blank
        expect(braintree_customer.phone).to be_blank

        expect(call).to be_a_success

        updated_braintree_customer = braintree_gateway.customer.find(braintree_customer.id)

        expect(updated_braintree_customer.first_name).to eq 'export_first_name'
        expect(updated_braintree_customer.last_name).to eq 'export_last_name'
        expect(updated_braintree_customer.email).to eq 'export@email.com'
        expect(updated_braintree_customer.phone).to eq '123'
      end

      it 'marks the braintree customer as filled' do
        expect(solidus_paypal_braintree_customer).not_to be_filled

        expect(call).to be_a_success

        expect(solidus_paypal_braintree_customer.reload).to be_filled
      end
    end
  end
end
