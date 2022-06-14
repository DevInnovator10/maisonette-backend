# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Calculator::PercentOnLineItemPresenter do
  let(:calculator) { create(:percent_on_item_calculator, preferred_percent: percent) }
  let(:code) { 'promotion_code' }

  describe '#advertised_text' do
    subject(:advertised_text) { described_class.new(calculator, code: code).advertised_text }

    context 'when preferred_percent is zero' do
      let(:percent) { 0 }

      it { is_expected.to be nil }
    end

    context 'when preferred_percent is greater than zero' do
      let(:percent) { 10 }

      it { is_expected.to eq 'Additional 10% OFF with code PROMOTION_CODE' }
    end
  end

  describe '#advertised_text_short' do
    subject(:advertised_text) { described_class.new(calculator, code: code).advertised_text_short }

    context 'when preferred_percent is zero' do
      let(:percent) { 0 }

      it { is_expected.to be nil }
    end

    context 'when preferred_percent is greater than zero' do
      let(:percent) { 10 }

      it { is_expected.to eq 'Additional 10% OFF with code PROMOTION_CODE' }
    end
  end
end
