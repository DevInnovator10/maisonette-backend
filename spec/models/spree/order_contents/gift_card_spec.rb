# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::OrderContents, type: :model do
  let(:shipping_category) { create(:shipping_category, name: 'Digital') }
  let(:order) { create(:order) }
  let(:order_contents) { order.contents }
  let(:variant) { create :variant, prices: [price] }
  let(:price) { create :price, vendor: create(:vendor) }
  let(:vendor) { price.vendor }
  let(:recipient_name) { 'Recipient name' }
  let(:recipient_email) { 'recipient@email.com' }
  let(:purchaser_name) { 'Purchaser name' }
  let(:gift_message) { 'Surprise recipient' }
  let(:send_email_at) { Time.zone.today.yesterday }
  let(:options) do
    {
      options: { vendor_id: vendor.id },
      gift_card_details: {
        'recipient_name' => recipient_name,
        'recipient_email' => recipient_email,
        'purchaser_name' => purchaser_name,
        'gift_message' => gift_message,
        'send_email_at' => send_email_at
      }
    }
  end
  let(:quantity) { 1 }
  let(:promotion) { create(:promotion, name: 'E-Gift Cards', promotion_category_id: gift_category.id) }
  let(:gift_category) { create(:promotion_category, name: 'E-Gift Card', code: 'e_gift_card', gift_card: true) }

  before do
    shipping_category
    promotion
  end

  describe '#add' do
    subject(:add) { order_contents.add(variant, quantity, options) }

    it 'creates a line item' do
      expect { add }.to change { Spree::LineItem.count }.by(1)
    end

    context 'with a gift card product' do
      before { variant.product.update(gift_card: true) }

      it 'creates a line item' do
        expect { add }.to change { Spree::LineItem.count }.by(1)
      end

      context 'with a single gift card' do
        it 'creates a gift card' do
          expect { add }.to change { Spree::GiftCard.count }.by(1)
        end

        it 'assignes the gift card attributes' do
          add

          gift_card = Spree::GiftCard.last

          expect(gift_card.recipient_name).to eq(recipient_name)
          expect(gift_card.recipient_email).to eq(recipient_email)
          expect(gift_card.purchaser_name).to eq(purchaser_name)
          expect(gift_card.gift_message).to eq(gift_message)
          expect(gift_card.send_email_at.to_date).to eq(Time.zone.today.yesterday)
        end

        context 'without send_email_at' do
          let(:send_email_at) { nil }

          it 'sets to current date' do
            add

            gift_card = Spree::GiftCard.last
            expect(gift_card.send_email_at.to_date).to eq(Time.zone.today)
          end
        end

        context 'with invalid date' do
          let(:send_email_at) { '12/14/2020' }

          it 'errors' do
            expect { add }.to raise_error Spree::OrderContents::GiftCard::GiftCardDateFormatError
          end
        end
      end

      context 'with multiple gift cards' do
        let(:quantity) { 2 }

        it 'creates two gift cards' do
          expect { add }.to change { Spree::GiftCard.count }.by(2)
        end
      end

      context 'when adding a gift card with an existing line item' do
        context 'when the gift card properties match' do
          it 'adds to the existing gift card' do
            order_contents.add(variant, quantity, options)

            expect(order.line_items.count).to be(1)

            new_line_item = order_contents.add(variant, quantity, options)

            expect(order.reload.line_items.count).to be(1)

            expect(new_line_item.reload.gift_cards.count).to be(2)
          end
        end

        context 'when the gift card properties are different' do
          subject(:add2) { order_contents.add(variant, quantity, options2) }

          let(:recipient_name2)  { 'Severus Snape' }
          let(:recipient_email2) { 'wingardium@leviosa.com' }
          let(:purchaser_name2)  { 'Dumbledore' }
          let(:options2) do
            {
              options: { vendor_id: vendor.id },
              gift_card_details: {
                'recipient_name' => recipient_name2,
                'recipient_email' => recipient_email2,
                'purchaser_name' => purchaser_name2,
                'gift_message' => gift_message,
                'send_email_at' => send_email_at
              }
            }
          end

          it 'creates a new line item with a gift card' do
            line_item = add

            expect(order.line_items.count).to be(1)

            new_line_item = add2

            expect(line_item.id).not_to eq new_line_item.id
            expect(order.reload.line_items.count).to be(2)
            expect(new_line_item.gift_cards.count).to be(1)
          end
        end
      end
    end

    context 'with a non gift card product' do
      it 'does not create a gift card' do
        expect { add }.not_to(change { Spree::GiftCard.count })
      end
    end
  end

  describe '#remove' do
    subject(:remove) { order_contents.remove(variant, quantity, options) }

    context 'when a non-gift-card product' do
      before { order_contents.add(variant, quantity, options) }

      it 'deletes a line item' do
        expect { remove }.to change { Spree::LineItem.count }.by(-1)
      end
    end

    context 'with a gift card product' do
      before do
        variant.product.update(gift_card: true)
      end

      context 'with a single gift card' do
        before do
          order_contents.add(variant, quantity, options)
        end

        it 'deletes a line item' do
          expect { remove }.to change { Spree::LineItem.count }.by(-1)
        end

        it 'deletes a gift card' do
          expect { remove }.to change { Spree::GiftCard.count }.by(-1)
        end

        it 'deletes a gift card promotion code' do
          expect { remove }.to change { Spree::PromotionCode.count }.by(-1)
        end
      end

      context 'with multiple gift cards' do
        let(:quantity) { 2 }

        before do
          order_contents.add(variant, quantity, options)
        end

        it 'deletes two gift cards' do
          expect { remove }.to change { Spree::GiftCard.count }.by(-2)
        end
      end

      context 'with two gift card line items with identical variants' do
        let(:recipient_name2)  { 'Severus Snape' }
        let(:recipient_email2) { 'wingardium@leviosa.com' }
        let(:purchaser_name2)  { 'Dumbledore' }
        let(:options2) do
          {
            options: { vendor_id: vendor.id },
            gift_card_details: {
              'recipient_name' => recipient_name2,
              'recipient_email' => recipient_email2,
              'purchaser_name' => purchaser_name2,
              'gift_message' => gift_message,
              'send_email_at' => send_email_at
            }
          }
        end
        let(:line_item) { order_contents.add(variant, quantity, options) }
        let(:line_item2) { order_contents.add(variant, quantity, options2) }

        before do
          line_item
          line_item2
        end

        context 'when removing the first line item' do
          it 'removes the correct line item' do
            expect(order.line_items.count).to be(2)

            remove

            expect(order.reload.line_items.count).to be(1)
            expect(order.line_items).not_to include(line_item)
          end
        end

        context 'when removing the second line item' do
          subject(:remove) { order_contents.remove(variant, quantity, options2) }

          it 'removes the correct line item' do
            expect(order.line_items.count).to be(2)

            remove

            expect(order.reload.line_items.count).to be(1)
            expect(order.line_items).not_to include(line_item2)
          end
        end
      end

      context 'when no gift card details are supplied' do
        subject(:remove) { order_contents.remove(variant, quantity, options) }

        let(:options) do
          {
            options: { vendor_id: vendor.id }
          }
        end

        before do
          order_contents.add(variant, quantity, options)
        end

        it 'removes the line item with the correct variant' do
          expect { remove }.to change { Spree::LineItem.count }.by(-1)
        end

        it 'removes the gift card' do
          expect { remove }.to change { Spree::GiftCard.count }.by(-1)
        end
      end
    end
  end
end
