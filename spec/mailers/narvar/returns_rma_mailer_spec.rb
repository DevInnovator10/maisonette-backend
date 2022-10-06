# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Narvar::ReturnsRmaMailer do
  include ActionMailer::TestHelper

  describe '#gift_card_email' do
    subject(:described_method) do
      described_class.gift_card_email(reimbursement_gift_card_id: reimbursement_gift_card_id)
    end

    let(:reimbursement_gift_card) do
      instance_double Spree::Reimbursement::GiftCard,
                      return_authorization: authorization,
                      spree_promotion_code: spree_promotion_code,
                      reimbursement: reimbursement,
                      update: true
    end

    let(:reimbursement_gift_card_id) { 1 }
    let(:reimbursement) { instance_double Spree::Reimbursement, total: amount }
    let(:spree_promotion_code) { instance_double Spree::PromotionCode, value: promo_code }
    let(:authorization) do
      instance_double Spree::ReturnAuthorization,
                      order: spree_order,
                      gift_recipient_email: gift_recipient_email
    end
    let(:spree_order) { instance_double(Spree::Order, id: 1, number: order_number) }
    let(:promo_code) { 'GIFTCODE' }
    let(:amount) { 50.5 }
    let(:order_number) { 'R1234' }
    let(:gift_recipient_email) { 'gift_recipient@email.com' }

    before do
      allow(Spree::Order).to receive(:find).and_return(spree_order)
      # allow(reimbursement_gift_card).to(receive(:update).and_return(true))
      allow(Spree::Reimbursement::GiftCard).to(
        receive(:find).with(reimbursement_gift_card_id).and_return(reimbursement_gift_card)
      )
    end

    it 'sends the email to gift_recipient_email address' do
      expect(described_method.to).to eq [gift_recipient_email]
    end

    it 'creates a gift_card_email with promo code' do
      expect(described_method.body).to include promo_code
    end

    it 'creates a gift_card_email with amount' do
      expect(described_method.body).to include amount
    end

    it 'creates a gift_card_email with promo code context' do
      expect(described_method.body).to include order_number
    end

    it 'updates the email_sent_at' do
      described_method.body

      expect(reimbursement_gift_card).to have_received(:update).with(hash_including(:email_sent_at))
    end
  end
end
