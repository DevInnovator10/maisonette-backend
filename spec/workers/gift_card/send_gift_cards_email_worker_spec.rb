# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GiftCard::SendGiftCardsEmailWorker do
  let(:gift_card) { instance_double(Spree::GiftCard) }
  let(:send_email) { true }

  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    let(:gift_cards_collection) { instance_double(ActiveRecord::Relation) }

    before do
      allow(Spree::GiftCard).to receive(:where).with('send_email_at <= ?', Time.zone.today.end_of_day) do
        gift_cards_collection
      end
      allow(gift_cards_collection).to receive(:where).with(sent_at: nil, redeemable: true) { gift_cards_collection }
      allow(gift_cards_collection).to receive(:find_each).and_yield(gift_card)
      allow(gift_card).to receive(:send_email)
    end

    it 'fetches giftcard with send_email_at less equal today' do
      perform

      expect(Spree::GiftCard).to have_received(:where).with('send_email_at <= ?', Time.zone.today.end_of_day)
      expect(gift_cards_collection).to have_received(:where).with(sent_at: nil, redeemable: true)

      expect(gift_card).to have_received(:send_email)
    end

    context 'when send_mail raise an error' do
      before do
        allow(gift_cards_collection).to receive(:where).and_raise('error')
        allow(Sentry).to receive(:capture_exception_with_message)
      end

      it 'captures the exeception' do
        perform

        expect(Sentry).to have_received(:capture_exception_with_message)
      end
    end
  end
end
