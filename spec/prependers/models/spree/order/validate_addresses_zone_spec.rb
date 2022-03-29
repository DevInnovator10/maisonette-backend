# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order::ValidateAddressesZone, type: :model do
  let(:described_class) { super().parent }

  describe '#errors' do
    subject { order.errors }

    let(:address) {}
    let(:zone) {}

    before do
      order
      zone
      order.next
    end

    describe 'address zone errors' do
      describe 'shipping address zone error' do
        let(:error_type) { :shipping_address_inclusion }
        let(:zone_name) { Spree::Zone::SHIPPING_ZONE_NAME }
        let(:order) { create :order_with_line_items, state: :address, ship_address: address }

        it_behaves_like 'an address zone validation'
      end

      describe 'billing address zone error' do
        let(:error_type) { :billing_address_inclusion }
        let(:zone_name) { Spree::Zone::BILLING_ZONE_NAME }
        let(:order) { create :order_with_line_items, state: :address, bill_address: address }

        it_behaves_like 'an address zone validation'
      end
    end
  end
end
