# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Kustomer::Reimbursement::GiftCardPresenter do
    describe '#kustomer_payload' do
    subject { described_class.new(gift_card).kustomer_payload }

    let(:gift_card) { create(:reimbursement_gift_card) }

    it do
      is_expected.to match hash_including(
        'type' => 'Spree::PromotionCode',
        'amount' => gift_card.amount,
        'emailSentAt' => gift_card.email_sent_at,
        'reimbursementNumber' => gift_card.reimbursement.number,
        'promotionCode' => gift_card.spree_promotion_code.gift_card.value
      )
    end

    context 'when the order is a legacy' do
      before { allow(gift_card.reimbursement.order).to receive(:legacy_order?).and_return(true) }

      it do
        is_expected.to match hash_including(
          'promotionCode' => nil
        )
      end
    end
  end
end
