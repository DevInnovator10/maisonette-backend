# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Price::SalePrices do
  let(:described_class) { Spree::Price }
  let(:price) { create :price, amount: 100.0 }

  describe '.on_sale' do
    subject { described_class.on_sale }

    before { prices }

    context 'when there are not any sale prices' do
      let(:prices) { create_list :price, 2 }

      it { is_expected.to match_array [] }
    end

    context 'when there are not any active sale prices' do
      let(:sale_prices) { create_list :sale_price, 2, enabled: false }
      let(:prices) { sale_prices.map(&:price) }

      it { is_expected.to match_array [] }
    end

    context 'when there are active sale prices' do
      let(:sale_prices) { create_list :sale_price, 2, enabled: true }
      let(:prices) { sale_prices.map(&:price) }

      it { is_expected.to match_array prices }
    end
  end

  describe '#active_sale' do
    subject { price.active_sale }

    context 'when there more enabled sale prices with different calculated prices' do
      let(:sale_price_1) do
        create :sale_price,
               price: price,
               enabled: true,
               value: 95.0 # 5% discount
      end
      let(:sale_price_2) do
        create :sale_price,
               price: price,
               enabled: true,
               value: 0.1, # 10% discount
               calculator: Spree::Calculator::PercentOffSalePriceCalculator.new

      end
      let(:sale_price_with_the_lowest_calculated_price) do
        create :sale_price,
               price: price,
               enabled: true,
               value: 80.0, # 20% discount
               created_at: sale_price_1.created_at - 1.day
      end

      before do
        sale_price_1
        sale_price_2
        sale_price_with_the_lowest_calculated_price
      end

      it { is_expected.to eq sale_price_with_the_lowest_calculated_price }
    end
  end

  describe '#next_active_sale' do
    subject { price.reload.next_active_sale }

    context 'when there more sale prices with different calculated prices' do
      let(:sale_price_1) do
        create :sale_price,
               price: price,
               value: 95.0 # 5% discount
      end
      let(:sale_price_2) do
        create :sale_price,
               price: price,
               value: 0.1, # 10% discount
               calculator: Spree::Calculator::PercentOffSalePriceCalculator.new
      end
      let(:sale_price_with_the_lowest_calculated_price) do
        create :sale_price,
               price: price,
               value: 80.0, # 20% discount
               created_at: sale_price_1.created_at - 1.day
      end

      before do
        sale_price_1
        sale_price_2
        sale_price_with_the_lowest_calculated_price
      end

      it { is_expected.to eq sale_price_with_the_lowest_calculated_price }
    end
  end
end
