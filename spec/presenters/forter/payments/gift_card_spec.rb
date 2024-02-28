# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forter::Payments::GiftCard do
  describe '#gift_card', freeze_time: true do
    subject(:gift_card) { FakeClass.new.send(:gift_card, gift_card_adjustment) }

    let(:gift_card_adjustment) do
      instance_double Spree::Adjustment,
                      id: 5,
                      amount: -50.10,
                      source: gift_card_source
    end
    let(:gift_card_source) do
      instance_double Spree::GiftCard,
                      starts_at: nil,
                      created_at: Time.current,
                      original_amount: 100.00,
                      recipient_email: 'admin1@maisonette.com',
                      line_item: line_item
    end
    let(:line_item) { instance_double Spree::LineItem, order: order }
    let(:order) { instance_double Spree::Order, email: 'admin2@maisonette.com' }

    it 'returns the gift card payload' do
      expect(gift_card).to(
        eq(giftCard: { merchantPaymentId: '5',
                       value: { amountUSD: '50.1',
                                currency: 'USD' },
                       activationTime: Time.current.to_i,
                       originalValue: { amountUSD: '100.0',
                                        currency: 'USD' },
                       emailOriginallySentTo: 'admin1@maisonette.com',
                       emailOriginallySentFrom: 'admin2@maisonette.com' },
           amount: {
             amountUSD: '50.1',
             currency: 'USD'
           })
      )
    end

    context 'when there is no git card source' do
      let(:gift_card_source) {}

      it 'returns the gift card payload without source attributes' do
        expect(gift_card).to(
          eq(giftCard: { merchantPaymentId: '5',
                         value: { amountUSD: '50.1',
                                  currency: 'USD' }, },
             amount: {
               amountUSD: '50.1',
               currency: 'USD'
             })
        )
      end
    end
  end
end

class FakeClass
  include Forter::Payments::GiftCard
end
