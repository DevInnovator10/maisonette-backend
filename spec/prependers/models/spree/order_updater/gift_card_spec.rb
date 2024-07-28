# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::OrderUpdater::GiftCard, type: :model do
  let(:order) { create(:order_with_line_items) }

  context 'when there is gift card promotion' do
    subject(:order_update) { Spree::OrderUpdater.new(order).update }

    let(:gift_card_amount) { 5 }
    let(:gift_card) { create(:spree_gift_card, original_amount: gift_card_amount) }
    let(:adjustment) do
      order.adjustments.create!(source: gift_card, order: order, label: 'test', amount: 0)
    end

    before { adjustment }

    it 'calculates gift card total' do
      expect { order_update }.to change { adjustment.reload.amount }.from(0).to(gift_card_amount * -1)
    end

    it 'persists gift card total' do
      expect { order_update }.to change(order, :gift_card_total).from(0).to(gift_card_amount * -1)
    end
  end

  describe '#adjustments' do
    subject(:updater) { Spree::OrderUpdater.new(order) }

    let(:gift_card_adjustment) { create(:adjustment, source_type: 'Spree::GiftCard') }

    before do
      order.adjustments << gift_card_adjustment
      order.adjustments << create(:adjustment, source_type: nil)
    end

    it 'does not return Spree::GiftCard adjustments' do
      expect(updater.adjustments).not_to include(gift_card_adjustment)
      expect(updater.adjustments.count).to eq 1
    end
  end
end
