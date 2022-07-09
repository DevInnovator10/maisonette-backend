# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::ReturnItem::Scopes do
  describe 'scope :line_item_return_quantity' do
    let(:return_item1) { create :return_item, inventory_unit: inventory_unit1 }
    let(:inventory_unit1) { create :inventory_unit, line_item: line_item1 }
    let(:return_item2) { create :return_item, inventory_unit: inventory_unit2 }
    let(:inventory_unit2) { create :inventory_unit, line_item: line_item1 }
    let(:return_item3) { create :return_item, inventory_unit: inventory_unit3 }
    let(:inventory_unit3) { create :inventory_unit, line_item: line_item1 }
    let(:line_item1) { create :line_item }

    let(:return_item4) { create :return_item, inventory_unit: inventory_unit4 }
    let(:inventory_unit4) { create :inventory_unit, line_item: line_item2 }
    let(:line_item2) { create :line_item }

    before do
      return_item1
      return_item2
      return_item3
      return_item4
    end

    it 'returns a count of return items that match a line item' do
      expect(Spree::ReturnItem.line_item_return_quantity(line_item1)).to eq 3
      expect(Spree::ReturnItem.line_item_return_quantity(line_item2)).to eq 1
    end
  end
end
