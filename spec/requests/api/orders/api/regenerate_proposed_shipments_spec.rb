# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'api/orders', type: :request do
  stub_authorization!

  describe 'PUT update' do
    context 'when the order has insufficient stock' do
      it 'does not raise InsufficientStock error' do
        order = create(:order_with_line_items)
        variant = order.line_items.first.variant
        variant.stock_items.first.set_count_on_hand(0)
        variant.stock_items.update(backorderable: false)

        expect do
          put spree.api_order_path(order),
              params: { order: { email: 'email@example.com' } }
        end.not_to raise_error(Spree::Order::InsufficientStock)
      end
    end
  end
end
