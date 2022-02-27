# frozen_string_literal: true

require 'rails_helper'
require 'rspec_api_documentation/dsl'

RSpec.resource 'OMS Promotion Eligible', type: :acceptance do
  header 'Accept', 'application/json'
  header 'Authorization', :bearer

  let(:bearer) { "Bearer #{spree_api_key}" }
  let(:spree_api_key) { user.spree_api_key }
  let(:user) { create :user, :with_oms_role }

  let(:promotion) { create(:promotion, :with_order_adjustment) }
  let(:promotion_code) { create :promotion_code, promotion: promotion }
  let(:order) { create(:completed_order_with_totals) }
  let(:order_number) { order.number }
  let(:coupon_code) { promotion_code.value }

  before do
    order.line_items.each do |line_item|
      create(:order_item_summary, summarable: line_item, order_management_ref: 'SF001')
    end
  end

  get '/api/oms/promotion_eligibility' do
    explanation 'Check which line items in the order are eligible for the coupon_code'

    parameter :order_number, 'Order number to check', required: true
    parameter :coupon_code, 'Coupon Code to apply', required: true

    example_request 'Return the eligible items for that coupon code' do
      expect(status).to eq 200

      expect(json_response['items']).to match array_including(hash_including(order_item_summary_ref: 'SF001'))
    end
  end
end
