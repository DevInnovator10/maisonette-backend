# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order::OrderManagement, type: :model do
  let(:described_class) { Spree::Order }

  it { is_expected.to have_one(:sales_order).class_name('OrderManagement::SalesOrder') }
  it { is_expected.to be_a(Maisonette::Flipper::Identifier) }

  describe '.forward_status' do
    subject(:forward_status) { Spree::Order.forward_status(status) }

    let(:order_forwarded) do
      create(:completed_order_with_totals, sales_order: create(:sales_order, order_management_ref: '123'))
    end
    let(:order_pending) do
      create(:completed_order_with_totals, sales_order: create(
        :sales_order, last_request_payload: nil, order_management_ref: nil
      ))
    end
    let(:order_error) do
      create(:completed_order_with_totals, sales_order: nil)
    end
    let(:order_failed) do
      create(:completed_order_with_totals, sales_order: create(
        :sales_order, last_request_payload: { data: 1 }, order_management_ref: nil
      ))
    end

    before do
      order_forwarded
      order_pending
      order_error
      order_failed
    end

    OrderManagement::SalesOrder::SALES_ORDER_FORWARD_STATUS.each do |state|
      context "when sales order status #{state}" do
        let(:status) { state }

        it "returns the proper order with sales order #{state}" do
          expect(forward_status).to eq [send("order_#{state}")]
        end
      end
    end
  end

  describe '#forwarded?' do
    subject(:forwarded?) { order.forwarded? }

    let(:order) { build_stubbed(:order, sales_order: sales_order) }

    context 'when order is forwarded' do
      let(:sales_order) do
        build_stubbed(:sales_order,
                      completed_at: Time.zone.now, order_management_ref: '123', last_request_payload: { data: '123' })
      end

      it 'returns true' do
        expect(forwarded?).to eq true
      end
    end

    context 'when order order_management_ref is nil' do
      let(:sales_order) do
        build_stubbed(:sales_order,
                      completed_at: Time.zone.now, order_management_ref: nil, last_request_payload: { data: '123' })
      end

      it 'returns false' do
        expect(forwarded?).to eq false
      end
    end

    context 'when order last_request_payload is nil' do
      let(:sales_order) do
        build_stubbed(:sales_order,
                      completed_at: Time.zone.now, order_management_ref: '123', last_request_payload: nil)
      end

      it 'returns false' do
        expect(forwarded?).to eq false
      end
    end
  end

  describe '#order_management_group?' do
    subject { order.order_management_group? }

    context 'when the user is present' do
      let(:user) { create(:user) }
      let(:order) { create(:order_with_line_items, user: user) }

      it { is_expected.to be_falsey }

      context 'when the user has oms spree role' do
        let(:user) { create(:user, :with_oms_backend_role) }

        it { is_expected.to be_truthy }
      end
    end

    context 'when the user is guest' do
      let(:order) { create(:order_with_line_items, user: nil, email: 'user@example.com') }

      it { is_expected.to be_falsey }

      context 'when the order email includes oms.test' do
        let(:order) { create(:order_with_line_items, user: nil, email: 'user.oms.test@example.com') }

        it { is_expected.to be_truthy }
      end
    end

    context 'when the order email is not present' do
      let(:order) { create(:order_with_line_items, user: nil, email: nil) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#send_to_order_management?' do
    subject { order.send_to_order_management? }

    let(:order) { create(:order_with_line_items) }

    before { allow(Flipper).to receive(:enabled?).with(:oms_place_order, order).and_return(enabled) }

    context 'when :place_order_on_oms is disabled' do
      let(:enabled) { false }

      it { is_expected.to be_falsey }
    end

    context 'when :place_order_on_oms is enabled' do
      let(:enabled) { true }

      it { is_expected.to be_truthy }
    end
  end

  describe '#historical_oms_payload' do
    subject { order.historical_oms_payload }

    let(:order) { build_stubbed(:order) }

    let(:order_presenter) do
      instance_double(OrderManagement::HistoricalOrderPresenter, payload: { order: 1 })
    end

    before do
      allow(OrderManagement::HistoricalOrderPresenter).to receive(:new).with(order) do
        order_presenter
      end
    end

    it { is_expected.to eq(order: 1) }
    it { is_expected.to eq(order.payload_for_oms_csv) }
  end
end
