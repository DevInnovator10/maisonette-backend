# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolidusAvataxCertified::Request::Base::CustomerCode do
  subject(:get_tax) { described_class.new(order, commit: false) }

  let(:described_class) { SolidusAvataxCertified::Request::GetTax }

  describe '#generate' do
    subject(:request) { get_tax.generate }

    context 'with a logged in user' do
      let(:user) { create(:user) }

      let(:maisonette_customer) { create(:maisonette_customer) }
      let(:order) { create(:order_with_line_items, maisonette_customer: maisonette_customer, user: user) }

      it 'returns maisonette customer id' do
        customer_code = request.dig(:createTransactionModel, :customerCode)

        expect(customer_code).to eq(order.maisonette_customer.id)
      end
    end

    context 'with a guest user' do
      let(:order) { create(:order_with_line_items) }

      it 'return order number' do
        customer_code = request.dig(:createTransactionModel, :customerCode)

        expect(customer_code).to eq(order.number)
      end
    end
  end
end
