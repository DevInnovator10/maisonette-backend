# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::OrderMailer::ConfirmEmail, type: :mailer do
  let(:described_class) { Spree::OrderMailer }

  let(:address) { create :address }
  let(:username) { FFaker::Name.first_name }
  let(:user) { create(:user, first_name: username) }
  let(:order) { create :shipped_order, user: user }

  describe '#confirm_email' do
    let(:described_method) { described_class.confirm_email(order) }

    it 'renders headers' do
      expect(described_method.to).to include order.email
      expect(described_method.from).to eq [Spree::Store.default.mail_from_address]
      expect(described_method.subject).to eq(
        'Maisonette | ' + I18n.t('spree.mail.order_confirmation.subject', order_number: order.number)
      )
    end

    it 'renders the body' do
      expect(described_method.body.encoded).to include I18n.t('spree.mail.order_confirmation.introduction',
                                                              number_of_shipments: order.shipments.length)
      expect(described_method.body.encoded).to include html_escape(I18n.t('spree.mail.order_confirmation.heading'))
      expect(described_method.body.encoded).to include order.ship_address.display_address
    end

    it 'renders the cta' do
      expect(described_method.body.encoded).to include 'View Order'
      expect(described_method.body.encoded).to include mail_url(order_url(order))
    end

    it 'does not render the jifiti footer' do
      expect(described_method.body.encoded).not_to match 'powered by Jifiti.com Inc.'
    end

    context 'when the payment is a store credit' do
      before do
        order.payments.clear
        order.payments << create(:store_credit_payment, :completed, amount: order.amount)
      end

      it 'renders the body' do
        expect(described_method.body.encoded).to include I18n.t('spree.mail.order_confirmation.introduction',
                                                                number_of_shipments: order.shipments.length)
        expect(described_method.body.encoded).to include html_escape(I18n.t('spree.mail.order_confirmation.heading'))
      end
    end

    context 'when the order is jifiti' do
      let(:order) { super().tap { |o| o.update(channel: 'jifiti', special_instructions: jifiti_instructions) } }
      let(:buyer_email) { 'admin@maisonette.com' }
      let(:buyer_name) { 'foo bar' }

      let(:jifiti_instructions) do
        "external_source: Jifiti Registry\r\n jifiti_receiver_email: #{user.email}\r\n " \
        "jifiti_buyer_email: #{buyer_email}\r\n jifiti_buyer_name: #{buyer_name}\r\n " \
        'jifiti_order_id: ABCD1234'
      end

      it 'sends email to the buyer, not the receiver' do
        expect(described_method.to).to eq([buyer_email])
      end

      it 'renders the jifiti translations' do
        expect(described_method.body.encoded).to match I18n.t('spree.mail.order_confirmation_jifiti.introduction')
        expect(described_method.body.encoded).to match I18n.t('spree.mail.order_confirmation_jifiti.heading')
        expect(described_method.subject).to eq(
          'Maisonette | ' + I18n.t('spree.mail.order_confirmation_jifiti.subject', order_number: order.number)
        )
      end

      it 'does not render the cta' do
        expect(described_method.body.encoded).not_to match 'View Order'
      end

      it 'renders the jifiti footer' do
        expect(described_method.body.encoded).to match 'powered by Jifiti.com Inc.'
      end

      it 'renders the order details' do
        expect(described_method.body.encoded).to match 'Order Details'
        expect(described_method.body.encoded).to match "Order Summary ##{order.number}"
      end

      it 'does not render the shipping address' do
        expect(described_method.body.encoded).not_to match 'Shipping To'
        expect(described_method.body.encoded).not_to match address.address1
      end

      context 'when order has gift card' do
        let(:line_item) { order.line_items.first }
        let(:product) { line_item.product }

        before do
          create(:shipping_category, name: 'Digital')
          product.update(gift_card: true)
        end

        it 'adds ops email to bcc' do
          expect(described_method.bcc).to match_array Maisonette::Config.fetch('mail.ops_support_email')
        end
      end
    end

    context 'when the order includes a monogram' do
      let(:line_item) { order.line_items.first }
      let(:order) { create :shipped_order }
      let(:offer_settings) do
        create :offer_settings,
               :with_monogram_customizations,
               variant: line_item.variant,
               vendor: line_item.vendor,
               monogrammable: true,
               monogram_price: 8.99
      end
      let(:line_item_monogram) { create(:line_item_monogram, line_item: line_item) }

      before do
        offer_settings
        line_item_monogram
        order.recalculate
      end

      it 'includes monogram details' do
        expect(described_method.body.encoded).to match 'Monogram'
      end

      context 'with empty customizations in the offer settings' do
        let(:offer_settings) do
          create :offer_settings,
                 variant: line_item.variant,
                 vendor: line_item.vendor,
                 monogrammable: true,
                 monogram_cost_price: 5.99,
                 monogram_price: 8.99,
                 monogram_max_text_length: 200
        end
        let(:line_item_monogram) do
          create(:line_item_monogram, line_item: line_item, customization: {}, text: 'A test', price: 123)
        end

        it 'includes monogram details' do
          expect(offer_settings.monogram_customizations).to be_empty
          expect(described_method.body.encoded).to match 'Monogram'
        end
      end
    end
  end
end
