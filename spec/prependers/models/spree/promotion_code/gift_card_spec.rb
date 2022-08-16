# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::PromotionCode::GiftCard, type: :model do
    let(:described_class) { Spree::PromotionCode }

  describe 'associations' do
    it do
      expect(described_class.new).to(
        have_one(:gift_card).class_name('Spree::GiftCard').with_foreign_key(:promotion_code_id).dependent(:destroy)
      )
    end
  end

  describe '#create' do
    let(:promotion_category) { create(:promotion_category, name: 'I am a GiftCard', gift_card: true) }

    context 'when promotion has a category set as gift card' do
      it 'allocates a gift card' do
        expect { create(:promotion, code: 'egift-test', promotion_category: promotion_category) }.to(
          change(Spree::GiftCard, :count).by(1)
        )
      end
    end
  end
end
