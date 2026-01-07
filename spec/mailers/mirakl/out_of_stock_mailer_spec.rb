# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::OutOfStockMailer do
  include ActionMailer::TestHelper
  include ActionView::Helpers::NumberHelper

  describe '#out_of_stock_email' do
    let(:message) do
      described_class.out_of_stock_email([order_line_reimbursement1, order_line_reimbursement2], promo_code: promo_code)
    end
    let(:order_line_reimbursement1) { build(:mirakl_order_line_reimbursement, id: 986, total: 20) }
    let(:order_line_reimbursement2) { build(:mirakl_order_line_reimbursement, id: 986, total: 20) }
    let(:promo_code) { '123ABC' }
    let(:mirakl_order) { order_line_reimbursement1.line_item.order }

    before do
      allow(Mirakl::OrderLineReimbursement).to(
        receive(:find).with(order_line_reimbursement1.id).and_return(order_line_reimbursement1)
      )
      allow(Mirakl::OrderLineReimbursement).to(
        receive(:find).with(order_line_reimbursement2.id).and_return(order_line_reimbursement2)
      )
    end

    it 'creates an out of stock email with a promo code' do
      expect(message.body).to(
        include I18n.t('spree.mail.mirakl_out_of_stock.introduction_promo_code',
                       order_number: mirakl_order.number,
                       promo_code: promo_code,
                       amount: number_to_currency(40))
      )
      expect(message.body).to include(
        'Thank you for your order! Unfortunately, one of the items you purchased is out of stock.'
      )
      expect(message.body).to include(promo_code)
    end

    it 'contains details for the refunded line item' do
      expect(message.body).to include order_line_reimbursement1.line_item.variant.product.name
      expect(message.body).to include order_line_reimbursement2.line_item.variant.product.name
    end

    context 'when there is no promo code' do
      let(:promo_code) { nil }

      it 'creates an out of stock email without a promo code' do
        expect(message.body).to(
          include I18n.t('spree.mail.mirakl_out_of_stock.introduction',
                         order_number: mirakl_order.number,
                         amount: number_to_currency(40))
        )
        expect(message.body).to include(
          'Thank you for your order! Unfortunately, one of the items you purchased is out of stock.'
        )
      end

      it 'contains details for the refunded line item' do
        expect(message.body).to include order_line_reimbursement1.line_item.variant.product.name
        expect(message.body).to include order_line_reimbursement2.line_item.variant.product.name
      end
    end
  end
end
