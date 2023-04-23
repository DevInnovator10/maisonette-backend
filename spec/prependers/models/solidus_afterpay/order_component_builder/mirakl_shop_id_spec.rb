# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolidusAfterpay::OrderComponentBuilder::MiraklShopId do
  let(:described_class) { SolidusAfterpay::OrderComponentBuilder }

  let(:order) { build(:order_with_line_items) }
  let(:redirect_confirm_url) { 'https://merchantsite.com/confirm' }
  let(:redirect_cancel_url) { 'https://merchantsite.com/cancel' }

  let(:builder) do
    described_class.new(
      order: order,
      redirect_confirm_url: redirect_confirm_url,
      redirect_cancel_url: redirect_cancel_url
    )
  end

  let(:line_item) { order.line_items.first }

  describe '#call' do
    subject(:result) { builder.call }

    let(:expected_result) do
      Afterpay::Components::Order.new(
        amount: Afterpay::Components::Money.new(amount: '110.0', currency: 'USD'),
        billing: Afterpay::Components::Contact.new(
          area1: 'Herndon',
          area2: nil,
          country_code: nil,
          line1: 'PO Box 1337',
          line2: 'Northwest',
          name: 'John Smith',
          phone_number: '555-555-0199',
          postcode: order.billing_address.zipcode,
          region: 'AL'
        ),
        consumer: Afterpay::Components::Consumer.new(
          email: order.user.email,
          given_names: 'John',
          phone_number: nil,
          surname: 'Smith'
        ),
        courier: nil,
        discounts: nil,
        items: [
          Afterpay::Components::Item.new(
            name: line_item.name,
            preorder: false,
            price: Afterpay::Components::Money.new(
              amount: '10.0',
              currency: 'USD'
            ),
            quantity: 1,
            sku: line_item.sku,
            categories: [[line_item.vendor.mirakl_shop.shop_id.to_s]]
          )
        ],
        merchant: Afterpay::Components::Merchant.new(
          redirect_confirm_url: 'https://merchantsite.com/confirm',
          redirect_cancel_url: 'https://merchantsite.com/cancel'
        ),
        merchant_reference: order.number,
        payment_type: nil,
        shipping: Afterpay::Components::Contact.new(
          area1: 'Herndon',
          area2: nil,
          country_code: nil,
          line1: 'A Different Road',
          line2: 'Northwest',
          name: 'John Smith',
          phone_number: '555-555-0199',
          postcode: order.shipping_address.zipcode,
          region: 'AL'
        ),
        shipping_amount: nil,
        tax_amount: nil
      )
    end

    it 'returns the correct payload' do
      expect(result.as_json).to eq(expected_result.as_json)
    end
  end
end
