# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::WalletPaymentSource::EnableGuestPaymentSource, type: :model do
  let(:described_class) { Spree::WalletPaymentSource }

  describe 'validation' do
    let(:user) { create(:user) }
    let(:another_user) { create(:user) }

    it 'is invalid when `payment_source` is owned by another user' do
      wallet_payment_source = described_class.new(
        payment_source: create(:credit_card, user: another_user),
        user: user
      )
      expect(wallet_payment_source).not_to be_valid
      expect(wallet_payment_source.errors.messages).to eq(
        payment_source: ['does not belong to the user associated with the order']
      )
    end

    it 'is valid when `payment_source#user_id` is nil' do
      wallet_payment_source = described_class.new(
        payment_source: create(:credit_card),
        user: user
      )
      expect(wallet_payment_source).to be_valid
    end
  end
end
