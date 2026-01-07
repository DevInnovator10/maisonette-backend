# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolidusAvataxCertified::Request::GetTax::FixDiscount do
  subject(:get_tax) { described_class.new(order, commit: false) }

  let(:described_class) { SolidusAvataxCertified::Request::GetTax }

  describe '#generate' do
    subject(:request) { get_tax.generate }

    context 'with no discounts' do
      let(:order) { create(:order_with_line_items) }

      it 'returns with 0 discount' do
        discount = request.dig(:createTransactionModel, :discount)

        expect(discount).to eq('0.0')
      end
    end

    context 'with free shipping' do
      let(:order) do
        create(:order_with_line_items,
               :with_promotion,
               promotion: create(:promotion, :with_free_shipping_adjustment))
      end

      it 'ignores the shipping promotion' do
        discount = request.dig(:createTransactionModel, :discount)

        expect(discount).to eq('0.0')
      end
    end

    context 'with order level discount' do
      let(:order) do
        create(:order_with_line_items,
               :with_promotion,
               promotion: create(:promotion_with_order_adjustment))
      end

      it 'includes the discount' do
        discount = request.dig(:createTransactionModel, :discount)

        expect(discount).to eq('10.0')
      end
    end

    context 'with line item level discount' do
      let(:order) do
        create(:order_with_line_items,
               :with_promotion,
               promotion: create(:promotion_with_item_adjustment))
      end

      it 'includes the discount' do
        discount = request.dig(:createTransactionModel, :discount)

        expect(discount).to eq('10.0')
      end
    end

    context 'with manual discount' do
      let(:order) { create(:order_with_line_items) }

      before do
        create(:adjustment,
               adjustable: order,
               order: order,
               amount: -5,
               label: 'Manual',
               source: create(:user))
      end

      it 'includes the discount' do
        discount = request.dig(:createTransactionModel, :discount)

        expect(discount).to eq('5.0')
      end
    end
  end
end
