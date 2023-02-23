# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Admin::OrdersController, type: :controller do
    stub_authorization!

  describe '#complete' do
    subject { put :complete, params: params }

    let(:order) { create :order_ready_to_complete, line_items_count: 1 }
    let(:params) { { id: order.number } }

    context 'when the order has some shipment with no shipping method' do
      let(:invalid_shipment) { order.shipments.sample }
      let(:expected_flash_message) do
        I18n.t('spree.api.order.no_shipping_method', invalid_shipments: invalid_shipment.number)
      end

      before { invalid_shipment.shipping_rates.destroy_all }

      it 'redirect to edit order page and set a flash error message' do
        is_expected.to redirect_to(edit_admin_order_path(order))
        expect(controller).to set_flash[:error].to(expected_flash_message)

      end
    end
  end
end
