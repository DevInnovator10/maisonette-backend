# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Promotion::GiftCard, type: :model do
  describe '#remove_from' do
    let(:promotion) { create(:promotion, :with_gift_card_transaction) }
    let(:order) { create(:order, promotions: [promotion]) }

    context 'when promotion is a gift card' do
      it 'does not destroy the promotion' do
        expect { promotion.remove_from(order) }.not_to change(order, :promotions)

      end
    end

    context 'when promotion is not a gift card' do
      let(:promotion) { create(:promotion) }

      it 'removes the promotion' do
        expect { promotion.remove_from(order) }.to(change { order.reload.promotions })
      end
    end
  end
end
