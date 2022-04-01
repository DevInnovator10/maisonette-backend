# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Promotion::Rules::AtLeastNOrders do
  describe '#applicable?' do
    subject { described_class.new.applicable?(promotable) }

    context 'when the promotable is an order' do
      let(:promotable) { Spree::Order.new }

      it { is_expected.to be true }
    end

    context 'when the promotable is not a order' do
      let(:promotable) { 'not an order' }

      it { is_expected.to be false }
    end
  end

  describe 'eligible?' do
    subject { instance.eligible?(order) }

    let(:instance) { described_class.new }

    before do
      instance.preferred_threshold_order_occurrence = 1
    end

    context 'when the order does not have an email' do
      let(:order) { Spree::Order.new }

      it { is_expected.to be false }
    end

    context 'when the order has a user' do
      let(:order) { create :order }
      let(:user) { order.user }

      context "when the user doesn't have completed orders" do
        it { is_expected.to be false }
      end

      context 'when the user has completed orders' do
        before do
          old_order = create :completed_order_with_totals, user: user, email: order.email
          old_order.update(completed_at: 1.day.ago)
        end

        context 'when this is the second order' do
          it { is_expected.to be true }

          context 'when the current order is completed' do
            let(:order) { create :order_ready_to_ship }

            it { is_expected.to be true }
          end
        end

        context 'when this is the third order' do
          before do
            another_old_order = create :completed_order_with_totals, user: user
            another_old_order.update(completed_at: 1.day.ago)
          end

          it { is_expected.to be true }

          context 'when the order is completed' do
            let(:order) { create :order_ready_to_ship }

            it { is_expected.to be true }
          end
        end
      end
    end

    context 'when the order has a guest user' do
      let(:email) { 'user_1@example.com' }
      let(:order) { create :order, user: nil, email: email }

      context 'when there are no other completed orders with the same email' do
        it { is_expected.to be false }
      end

      context 'when there are other orders with the same email of the current order' do
        before do
          old_order = create :completed_order_with_totals, user: nil, email: email
          old_order.update(completed_at: 1.day.ago)
        end

        context 'when this is the second order' do
          it { is_expected.to be true }

          context 'when the current order is completed' do
            let(:order) { create :order_ready_to_ship, user: nil, email: email }

            it { is_expected.to be true }
          end
        end

        context 'when this is the third order' do
          before do
            another_old_order = create :completed_order_with_totals, user: nil, email: email
            another_old_order.update(completed_at: 1.day.ago)
          end

          it { is_expected.to be true }

          context 'when the order is completed' do
            let(:order) { create :order_ready_to_ship, user: nil, email: email }

            it { is_expected.to be true }
          end
        end
      end
    end
  end
end
