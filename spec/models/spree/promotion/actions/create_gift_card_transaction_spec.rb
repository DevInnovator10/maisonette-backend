# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Promotion::Actions::CreateGiftCardTransaction, type: :model do
  let(:action) { described_class.new }
  let(:order) { create(:order_with_line_items) }
  let(:promotion_code) { build_stubbed(:promotion_code, gift_card: gift_card) }
  let(:gift_card) { build_stubbed(:spree_gift_card, redeemable: redeemable) }
  let(:redeemable) { true }
  let(:payload) { { order: order, promotion_code: promotion_code } }
  let(:promotion) { build_stubbed(:promotion) }

  before do
    allow(gift_card).to receive(:compute_amount).with(order).and_return(-10)
    allow(action).to receive_messages(promotion: promotion)
  end

  describe '#perform' do
    context 'when gift card is not redeemable' do
      let(:redeemable) { false }

      it 'returns false' do
        expect(action.perform(payload)).to eq false
      end
    end

    context 'when gift card is expired' do
      let(:gift_card) { build_stubbed(:spree_gift_card, redeemable: true, expires_at: 1.day.ago) }

      it 'returns false' do
        expect(action.perform(payload)).to eq false
      end
    end

    context 'when gift card is redeemable' do
      it 'creates an adjustment' do
        expect { action.perform(payload) }.to change { Spree::Adjustment.count }.by(1)
      end

      context 'when there is already an adjustment' do
        it 'updates the adjustment' do
          action.perform(payload)

          allow(gift_card).to receive(:compute_amount).with(order).and_return(-20)

          expect { action.perform(payload) }.to change { Spree::Adjustment.last.amount }.from(-10).to(-20)
        end
      end
    end
  end

  describe '#remove_from' do
    let(:gift_card_1) { create(:spree_gift_card, promotion_code: create(:promotion_code)) }
    let(:gift_card_2) { create(:spree_gift_card, promotion_code: create(:promotion_code)) }
    let(:adjustment_1) { create(:adjustment, source: gift_card_1) }
    let(:adjustment_2) { create(:adjustment, source: gift_card_2) }
    let(:no_gift_card_adjustment) { create(:adjustment) }
    let(:adjustments) { [adjustment_1, adjustment_2, no_gift_card_adjustment] }

    before do
      order.adjustments = adjustments
    end

    it 'removes the adjustment from the order' do
      order.coupon_code = gift_card_1.value

      expect { action.remove_from(order) }.to(
        change { order.reload.adjustments }.from(adjustments).to([adjustment_2, no_gift_card_adjustment])
      )
    end
  end
end
