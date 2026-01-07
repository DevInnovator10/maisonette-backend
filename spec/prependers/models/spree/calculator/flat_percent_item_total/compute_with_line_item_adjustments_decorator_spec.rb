# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Calculator::FlatPercentItemTotal::ComputeWithLineItemAdjustments do
  let(:described_class) { Spree::Calculator::FlatPercentItemTotal }

  describe '#compute' do
    subject(:compute) { flat_percent_item_calc.compute(order) }

    let(:flat_percent_item_calc) { described_class.new }
    let(:order) do
      instance_double Spree::Order,
                      item_total: 100.0,
                      line_item_adjustments: line_item_adjustments,
                      currency: 'USD'
    end
    let(:usd_currency) { instance_double Money::Currency, exponent: 2 }
    let(:line_item_adjustments) { class_double Spree::Adjustment, non_tax: non_tax_adjustments }
    let(:non_tax_adjustments) { class_double Spree::Adjustment, sum: -10 }

    before do
      allow(order).to receive(:is_a?).with(Spree::Order).and_return(true)
      allow(Money::Currency).to receive(:find).with('USD').and_return(usd_currency)
      allow(flat_percent_item_calc).to receive(:preferred_flat_percent).and_return(10.0)
    end

    it 'computes the promotion after line item promotions' do
      expect(compute).to eq 9.0
    end
  end
end
