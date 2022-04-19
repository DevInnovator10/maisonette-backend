# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::AllocateGiftCardInteractor do
  let(:promotion) { create(:promotion, name: 'E-Gift Cards', promotion_category_id: gift_category.id) }
  let(:gift_category) { create(:promotion_category, name: 'E-Gift Card', code: 'e_gift_card', gift_card: true) }
  let(:order) { instance_double Spree::Order, number: 'R123' }
  let(:promotion_code) { promotion.codes.first }
  let(:gift_card) { promo_code.gift_card }
  let(:name) { nil }
  let(:line_item) { build_stubbed(:line_item) }
  let(:recipient_email) { 'recipient@email.com' }
  let(:purchaser_name) { 'Purchaser' }

  describe '#call' do
    subject(:interactor) { described_class.call(interactor_context) }

    let(:interactor_context) do
      {
        order: order,
        name: name,
        line_item_id: line_item.id,
        recipient_email: recipient_email,
        purchaser_name: purchaser_name
      }
    end

    before { promotion }

    it { is_expected.to be_a_success }

    it 'adds a promotion to the context' do
      expect(interactor.promotion).to eq promotion
    end

    it 'creates a gift card' do
      expect(interactor.gift_card.redeemable).to eq false
      expect(interactor.gift_card.state).to eq 'allocated'
      expect(interactor.gift_card.line_item_id).to eq line_item.id
      expect(interactor.gift_card.recipient_email).to eq recipient_email
      expect(interactor.gift_card.purchaser_name).to eq purchaser_name
    end

    context 'when name is passed' do
      let(:name) { 'test gift card' }

      it 'names the gift card with context name' do
        expect(interactor.gift_card.name).to eq name
      end
    end

    context 'when name is not passed' do
      it 'names the gift card by order number' do
        expect(interactor.gift_card.name).to eq "E-Gift Card - #{order.number}"
      end
    end

    it 'adds a promotion promotion_code instance to the context' do
      expect(interactor.promotion_code).to eq promotion.codes.first
    end
  end

  describe '#create_unique_promo_code' do
    subject(:create_unique_promo_code) { interactor.send :create_unique_promo_code }

    let(:interactor) { described_class.new }

    context 'when there is no other matching code' do
      before do
        allow(Spree::PromotionCode).to receive(:exists?).with(value: anything).and_return(false)
      end

      it 'returns an 8 length code' do
        expect(create_unique_promo_code.length).to eq 8
      end
    end

    context 'when there is a matching code' do
      before do
        allow(Spree::PromotionCode).to receive(:exists?).with(value: anything).and_return(true, false)
      end

      it 'returns a 9 length code' do
        expect(create_unique_promo_code.length).to eq 9
      end
    end
  end

  describe 'failure' do
    context 'when GiftCard update fails' do
      subject(:interactor) { described_class.call(interactor_context) }

      let(:interactor_context) do
        {
          order: order,
          name: name,
          line_item_id: line_item.id,
          recipient_email: recipient_email,
          purchaser_name: purchaser_name,
          original_amount: 0.0
        }
      end

      before { promotion }

      it "doesn't raise the error" do
        expect { interactor }.not_to raise_error
      end

      it 'rollbacks the PromotionCode' do
        expect { interactor }.not_to change(Spree::PromotionCode, :count)
      end
    end
  end
end
