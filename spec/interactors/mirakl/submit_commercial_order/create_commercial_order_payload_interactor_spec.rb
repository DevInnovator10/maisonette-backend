# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::SubmitCommercialOrder::CreateCommercialOrderPayloadInteractor, mirakl: true do
    describe '#call' do
    let(:expected_result) do
      { 'commercial_id': 'R0001112223',
        'scored': 'true',
        'shipping_zone_code': 'USA',
        'payment_workflow': 'PAY_ON_ACCEPTANCE',
        'payment_info': { payment_type: '' },
        'customer': { 'customer_id': 'user@example.com',
                      'email': 'user@example.com',
                      'firstname': 'John',
                      'lastname': 'Doe',
                      'billing_address': { 'city': order.bill_address.city,
                                           'company': order.bill_address.company,
                                           'country': order.bill_address.country.iso_name,
                                           'country_iso_code': 'USA',
                                           'firstname': order.bill_address.first_name,
                                           'lastname': order.bill_address.last_name,
                                           'phone': order.bill_address.phone,
                                           'phone_secondary': order.bill_address.alternative_phone,
                                           'state': order.bill_address.state&.name,
                                           'street_1': order.bill_address.address1,
                                           'street_2': order.bill_address.address2,
                                           'zip_code': order.bill_address.zipcode },
                      'shipping_address': { 'city': order.ship_address.city,
                                            'company': order.ship_address.company,
                                            'country': order.ship_address.country.iso_name,
                                            'country_iso_code': 'USA',
                                            'firstname': order.ship_address.first_name,
                                            'lastname': order.ship_address.last_name,
                                            'phone': order.ship_address.phone,
                                            'phone_secondary': order.ship_address.alternative_phone,
                                            'state': order.ship_address.state.name,
                                            'street_1': order.ship_address.address1,
                                            'street_2': order.ship_address.address2,
                                            'zip_code': order.ship_address.zipcode } },
        'offers': offers_array,
        'order_additional_fields': order_additional_fields }
    end
    let(:order_additional_fields) { [{ code: MIRAKL_DATA[:order][:additional_fields][:env], value: Rails.env }] }
    let(:order) { build_stubbed :order_ready_to_ship, number: 'R0001112223', user: user, email: 'user@example.com' }
    let(:user) { build_stubbed :user, first_name: 'John', last_name: 'Doe', email: 'user@example.com' }
    let(:offers_array) { ['array_of_offer_details'] }

    let(:context) { described_class.call offers_details_payload: offers_array, spree_order: order }

    it 'creates the payload with user and offers details' do
      expect(context.commercial_order_payload).to eq expected_result.to_json
    end

    context 'when it fails' do
      let(:interactor) { described_class.new }
      let(:exception) { StandardError.new 'foo' }

      before do
        allow(interactor).to receive(:handle_exception)
        allow(interactor).to receive(:context).and_raise(exception)

        interactor.call
      end

      it 'calls #handle_exception' do
        expect(interactor).to have_received(:handle_exception).with(exception)
      end
    end

    context 'when the billing address state is empty' do
      before do
        order.billing_address.state = nil
      end

      it 'creates the payload with the billing address state as nil' do
        expect(JSON.parse(context.commercial_order_payload)).to(
          match(hash_including('customer' => hash_including('billing_address' => hash_including('state' => nil))))
        )
      end
    end

    context 'when the customers email/customer id is over 50 characters' do
      before do
        order.email = 'X' * 51
      end

      it 'sends the customer_id limited to 50 characters' do
        expect(JSON.parse(context.commercial_order_payload)).to(
          match(hash_including('customer' => hash_including('customer_id' => ('X' * 50))))
        )
      end
    end
  end

  describe '#payment_method_type' do
    let(:payment_method_type) { described_class.new(spree_order: order).send :payment_method_type }
    let(:order) { instance_double Spree::Order, payments: payments, number: 'R123456' }
    let(:payments) { class_double Spree::Payment, valid: valid_payments }
    let(:valid_payments) do
      class_double Spree::Payment,
                   store_credits: store_credits,
                   not_store_credits: not_store_credits,
                   first: first_payment
    end
    let(:first_payment) { nil }
    let(:store_credits) { [store_credit_payment] }
    let(:not_store_credits) { [payment] }
    let(:store_credit_payment) { build_stubbed :store_credit_payment }
    let(:payment) { build_stubbed :payment }

    context 'when there are both store credit and non store credit payments' do
      it 'returns Mixed' do
        expect(payment_method_type).to eq MIRAKL_DATA[:order][:payment_type][:mixed]
      end
    end

    context 'when there are only store credit payments' do
      let(:not_store_credits) { [] }
      let(:first_payment) { store_credit_payment }

      it 'returns the payment method name' do
        expect(payment_method_type).to eq 'Store Credit'
      end
    end

    context 'when there are only credit card payments' do
      let(:store_credits) { [] }
      let(:first_payment) { payment }

      it 'returns the payment method name' do
        expect(payment_method_type).to eq 'Credit Card'
      end
    end

    context 'when it fails' do
      let(:valid_payments) { nil }
      let(:error_message) do

        I18n.t('errors.mirakl_submit_order_missing_payment_info',
               order_number: order.number)
      end

      before do
        allow(Sentry).to receive(:capture_message)

        payment_method_type
      end

      it 'returns an empty string' do
        expect(payment_method_type).to eq ''
      end

      it 'captures the error message in Sentry' do
        expect(Sentry).to have_received(:capture_message).with(error_message)
      end
    end
  end
end
