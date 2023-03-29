# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::GiftCardTransaction, type: :model do
    it { is_expected.to belong_to(:gift_card) }

  describe '.redeemed' do
    subject(:redeemed) { Spree::GiftCardTransaction.redeemed }

    let!(:redeemed_gift_card) { create(:spree_gift_card, :with_transaction) }
    let(:transaction) { redeemed_gift_card.gift_card_transactions.first }

    it 'returns redeemed transactions' do
      expect(redeemed).to eq [transaction]
    end
  end
end
