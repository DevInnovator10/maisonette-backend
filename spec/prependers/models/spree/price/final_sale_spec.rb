# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Price::FinalSale do
  describe '#final_sale?' do
    subject { price }

    let(:price) { create(:price) }
    let(:final_sale) { false }

    before { price }

    it { is_expected.not_to be_final_sale }

    context 'when offer_setting is present' do
      let(:final_sale) { nil }
      let(:offer_setting) do
        create :offer_settings, variant: price.variant, vendor: price.vendor, final_sale: final_sale
      end

      before { offer_setting }

      it { is_expected.not_to be_final_sale }

      context 'when sale_price is final_sale' do
        let(:final_sale) { true }

        before do
          create(:sale_price, enabled: true, price: price, final_sale: final_sale)
        end

        it { is_expected.to be_final_sale }
      end

      context 'with final_sale sets as true' do
        let(:final_sale) { true }

        it { is_expected.to be_final_sale }
      end
    end
  end
end
