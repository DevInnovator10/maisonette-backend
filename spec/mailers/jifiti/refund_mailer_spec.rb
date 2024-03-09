# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Jifiti::RefundMailer do
    include ActionMailer::TestHelper

  before do
    allow(Maisonette::Config).to receive(:fetch).and_call_original
    # To skip Narvar order / shipments callbacks:
    allow(Maisonette::Config).to receive(:fetch).with('narvar.api_url').and_return(nil)
    allow(Maisonette::Config).to receive(:fetch).with('jifiti.order_email').and_return(nil)
    allow(Maisonette::Config).to receive(:fetch).with('jifiti.mais_order_email').and_return(nil)
  end

  describe '.refund_not_shipped_order' do
    subject(:described_method) { described_class.refund_not_shipped_order(order, refund) }

    let(:order) do
      create(:order,
             shipment_state: 'shipped',
             special_instructions: "external_source : Jifiti Registry\r\n jifiti_order_id: 148734")
    end
    let(:refund) { create :mirakl_order_line_reimbursement }

    it { expect { described_method.deliver_now }.to raise_error(ArgumentError) }

    context 'when JIFITI_ORDER_EMAIL key is present' do
      before do
        allow(Maisonette::Config).to receive(:fetch).with('jifiti.order_email').and_return('test@example.com')
        allow(Maisonette::Config).to receive(:fetch).with('jifiti.mais_order_email').and_return('bcc@example.com')
      end

      it 'sends the email to jifiti and maisonette customercare' do
        expect(described_method.to).to include 'test@example.com'
        expect(described_method.bcc).to include 'bcc@example.com'
        expect(described_method.subject).to eq(
          I18n.t('spree.mail.refund_jifiti_not_shipped_order.subject', order_number: order.number)
        )
      end

      it 'contains some useful information' do
        expect(described_method.body).to include order.number
        expect(described_method.body).to include 'SKU'
        expect(described_method.body).to include refund.inventory_units.first.variant.sku
      end

      context 'when mirakl_order_line_reimbursement is missing' do
        let(:refund) { nil }

        it 'sends the email to jifiti and maisonette customercare' do
          expect(described_method.to).to include 'test@example.com'
          expect(described_method.bcc).to include 'bcc@example.com'
          expect(described_method.subject).to eq(
            I18n.t('spree.mail.refund_jifiti_not_shipped_order.subject', order_number: order.number)
          )
          expect(described_method.body).to include order.number
          expect(described_method.body).not_to include 'SKU'
        end
      end
    end
  end

  describe '.error_refund_shipped_order' do
    subject(:described_method) { described_class.error_refund_shipped_order(order) }

    let(:order) do
      create(
        :order,
        shipment_state: 'shipped',
        special_instructions: "external_source : Jifiti Registry\r\n jifiti_order_id: 148734"
      )
    end

    it { expect { described_method.deliver_now }.to raise_error(ArgumentError) }

    context 'when JIFITI_ORDER_EMAIL key is present' do
      before do
        allow(Maisonette::Config).to receive(:fetch).with('jifiti.mais_order_email').and_return('test@example.com')
      end

      it 'sends the email to jifiti and maisonette customercare' do
        expect(described_method.to).to include 'test@example.com'
        expect(described_method.subject).to eq(
          I18n.t('spree.mail.error_refund_jifiti_shipped_order.subject', order_number: order.number)
        )
        expect(described_method.body).to include order.number
      end
    end
  end
end
