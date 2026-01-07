# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::PromotionCode::Base, type: :model do
  let(:described_class) { Spree::PromotionCode }

  describe '.generate_code' do
    subject(:code) { described_class.generate_code }

    context 'when there is no other matching code' do
      before { allow(Spree::PromotionCode).to receive(:exists?).with(value: anything).and_return(false) }

      it 'returns an 8 length code' do
        expect(code.length).to eq 8
      end
    end

    context 'when there is a matching code' do
      before { allow(Spree::PromotionCode).to receive(:exists?).with(value: anything).and_return(true, false) }

      it 'returns a 9 length code' do
        expect(code.length).to eq 9
      end
    end
  end

  describe '#active?' do
    subject { promotion_code.active? }

    let(:promotion_code) { described_class.new }
    let(:promotion) { instance_double Spree::Promotion }

    before { allow(promotion_code).to receive(:promotion).and_return promotion }

    context 'when promotion is inactive' do
      before { allow(promotion).to receive(:active?).and_return false }

      it { is_expected.to be_falsey }
    end

    context 'when the promotion is active' do
      before { allow(promotion).to receive(:active?).and_return true }

      context 'when the promotion_code has no expires_at' do
        before { promotion_code.expires_at = nil }

        it { is_expected.to be_truthy }
      end

      context 'when the promotion_code has an expires_at date in the future' do
        before { promotion_code.expires_at = 1.week.from_now }

        it { is_expected.to be_truthy }
      end

      context 'when the promotion_code has an expires_at date in the past' do
        before { promotion_code.expires_at = 1.week.ago }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#inactive?' do
    subject { promotion_code.inactive? }

    let(:promotion_code) { described_class.new }
    let(:promotion) { instance_double Spree::Promotion }

    before { allow(promotion_code).to receive(:promotion).and_return promotion }

    context 'when promotion is inactive' do
      before { allow(promotion).to receive(:active?).and_return false }

      it { is_expected.to be_truthy }
    end

    context 'when the promotion is active' do
      before { allow(promotion).to receive(:active?).and_return true }

      context 'when the promotion_code has no expires_at' do
        before { promotion_code.expires_at = nil }

        it { is_expected.to be_falsey }
      end

      context 'when the promotion_code has an expires_at date in the future' do
        before { promotion_code.expires_at = 1.week.from_now }

        it { is_expected.to be_falsey }
      end

      context 'when the promotion_code has an expires_at date in the past' do
        before { promotion_code.expires_at = 1.week.ago }

        it { is_expected.to be_truthy }
      end
    end
  end
end
