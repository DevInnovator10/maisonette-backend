# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::OrderSummary, type: :model do

  it { is_expected.to belong_to(:sales_order).required }

  describe '.order_management_object_name' do
    it 'returns the oms object name' do
      expect(described_class.order_management_object_name).to eq 'OrderSummary'
    end
  end
end
