# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolidusAvataxCertified::Line::MerchantSellerIdentifier, type: :model do
  describe '#item_line' do
    let(:order) { create(:order_with_line_items) }
    let(:line) { SolidusAvataxCertified::Line.new(order, 'SalesOrder') }

    it 'adds merchantSellerIdentifier when a SolidusAvataxCertified::Line is prepared' do
      expected_value = order.line_items.first.vendor.avalara_code

      expect(line.lines.first).to include(merchantSellerIdentifier: expected_value)
    end
  end
end
