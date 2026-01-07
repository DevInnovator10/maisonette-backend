# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::RefundMailer, type: :mailer do
  let(:refund) { create(:refund) }
  let(:order) { refund.payment.order }
  let(:user) { create(:user) }

  it 'includes MailerHelper' do
    expect(described_class.ancestors).to include(MailerHelper)
  end

  describe '#refund_email' do
    let(:mail) { described_class.refund_email(refund) }

    it 'renders the headers' do
      expect(mail.to).to include refund.payment.order.email
      expect(mail.from).to eq [Spree::Store.default.mail_from_address]
    end

    it 'renders the cta' do
      expect(mail.body.encoded).to include 'View Order'
      expect(mail.body.encoded).to include mail_url order_url(order)
    end

    context 'when issuing a refund' do
      before { allow(refund).to receive(:store_credit_refund?).and_return(false) }

      it 'renders the header with the correct text' do
        expect(mail.subject).to include I18n.t('spree.mail.refund.subject', order_number: order.number)
      end

      it 'renders the body with the correct text' do
        expect(mail.body.encoded).to include(
          I18n.t('spree.mail.refund.introduction', amount: refund.display_amount, order_number: order.number)
        )
      end
    end

    context 'when issuing a store credit' do
      before { allow(refund).to receive(:store_credit_refund?).and_return(false) }

      it 'renders the subject with the correct text' do
        expect(mail.subject).to include I18n.t('spree.mail.refund_store_credit.subject', order_number: order.number)
      end

      it 'renders the body with the correct text' do
        expect(mail.body.encoded).to include(
          I18n.t('spree.mail.refund.introduction', amount: refund.display_amount, order_number: order.number)
        )
      end
    end

    context 'when issuing a store credit' do
      before { allow(refund).to receive(:store_credit_refund?).and_return(true) }

      it 'renders the subject with the correct text' do
        expect(mail.subject).to include I18n.t('spree.mail.refund_store_credit.subject', order_number: order.number)
      end

      it 'renders the body with the correct text' do
        expect(mail.body.encoded).to include(
          I18n.t('spree.mail.refund_store_credit.introduction',
                 amount: refund.display_amount, order_number: order.number)
        )
      end
    end
  end

  context 'when the refund comes from jifiti' do
    subject(:message) { described_class.refund_email(refund) }

    let(:payment) { create(:jifiti_payment, order: order) }
    let(:refund) { create(:refund, payment: payment, amount: 9.99) }

    context 'when the order is shipped' do
      let(:order) { create(:order, shipment_state: 'shipped') }

      it 'sends an email' do
        expect(message.body).to include 'to your account as Store Credit'
      end
    end

    context 'when the order is not shipped' do
      let(:order) { create(:order) }

      it 'sends an email' do
        expect(message.body).to include "We've refunded the order ##{order.number}"
      end
    end
  end
end
