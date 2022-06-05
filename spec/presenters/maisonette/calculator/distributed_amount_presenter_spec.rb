# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Calculator::DistributedAmountPresenter do
  let(:calculator) { create(:distributed_amount_calculator, preferred_amount: amount) }
  let(:code) { 'promotion_code' }

  describe '#advertised_text' do
    subject(:advertised_text) { described_class.new(calculator, code: code).advertised_text }

    context 'when preferred_amount is zero' do
      let(:amount) { 0 }

      it { is_expected.to be nil }
    end

    context 'when preferred_amount is greater than zero' do
      let(:amount) { 10.0 }

      it { is_expected.to eq 'Up to $10 OFF with code PROMOTION_CODE' }
    end
  end

  describe '#advertised_text_short' do
    subject(:advertised_text) { described_class.new(calculator, code: code).advertised_text_short }

    context 'when preferred_amount is zero' do
      let(:amount) { 0 }

      it { is_expected.to be nil }
    end

    context 'when preferred_amount is greater than zero' do
      let(:amount) { 10.0 }

      it { is_expected.to eq 'Up to $10 OFF with code PROMOTION_CODE' }
    end
  end
end
