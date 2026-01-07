# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::OfferSettings::MonogramCustomizations, type: :model do
  describe '#blank' do
    subject { described_class.new(hash).blank? }

    context 'when it is a empty hash' do
      let(:hash) { {} }

      it { is_expected.to be_truthy }
    end

    context 'when it is a hash with no customizations' do
      let(:hash) { { 'colors' => [] } }

      it { is_expected.to be_truthy }
    end

    context 'when it is a hash with some customizations' do
      let(:hash) { { 'colors' => [{ 'name' => 'fake name', 'value' => 'fake value' }] } }

      it { is_expected.to be_falsey }
    end
  end

  describe '#any_of_type?' do
    subject { described_class.new(hash).any_of_type?(type) }

    let(:type) { 'colors' }

    context 'when it is a empty hash' do
      let(:hash) { {} }

      it { is_expected.to be_falsey }
    end

    context 'when it is a hash with no customizations' do
      let(:hash) { { 'colors' => [] } }

      it { is_expected.to be_falsey }
    end

    context 'when it is a hash with some customizations' do
      let(:hash) { { 'colors' => [{ 'name' => 'fake name', 'value' => 'fake value' }] } }

      it { is_expected.to be_truthy }
    end
  end

  describe '#exists?' do
    subject { described_class.new(hash).exists?(type, customization) }

    let(:type) { 'colors' }
    let(:customization) { { 'name' => 'fake name', 'value' => 'fake value' } }

    context 'when it is a empty hash' do
      let(:hash) { {} }

      it { is_expected.to be_falsey }
    end

    context 'when it is a hash with no customizations' do
      let(:hash) { { 'colors' => [] } }

      it { is_expected.to be_falsey }
    end

    context 'when it is a hash with the same customization of a different type' do
      let(:hash) { { 'fonts' => [{ 'name' => 'fake name', 'value' => 'fake value' }] } }

      it { is_expected.to be_falsey }
    end

    context 'when it is a hash with a different customization of the same type' do
      let(:hash) { { 'colors' => [{ 'name' => 'other fake name', 'value' => 'other fake value' }] } }

      it { is_expected.to be_falsey }
    end

    context 'when it is a hash with the same customization of the same type' do
      let(:hash) { { 'colors' => [{ 'name' => 'fake name', 'value' => 'fake value' }] } }

      it { is_expected.to be_truthy }
    end
  end

  describe '#valid?' do
    context 'when there are not any errors' do
      let(:described_instance) { described_class.new(hash) }

      before do
        allow(described_instance).to receive(:errors).and_return([])
      end

      it { expect(described_instance).to be_valid }
    end

    context 'when there are some errors' do
      let(:described_instance) { described_class.new(hash) }

      before do
        allow(described_instance).to receive(:errors).and_return(['some error'])
      end

      it { expect(described_instance).not_to be_valid }
    end

    context 'when called twice' do
      let(:described_instance) { described_class.new(hash) }
      let(:hash) { {} }

      before do
        allow(described_instance).to receive(:validate!) { described_instance.errors.add :base, :invalid }
        allow(described_instance).to receive(:valid?).and_call_original

        described_instance.valid?
        described_instance.valid?
      end

      it 'does not add the same error' do
        expect(described_instance.errors.size).to eq 1
      end
    end
  end

  describe '#invalid?' do
    context 'when there are not any errors' do
      let(:described_instance) { described_class.new(hash) }

      before do
        allow(described_instance).to receive(:errors).and_return([])
      end

      it { expect(described_instance).not_to be_invalid }
    end

    context 'when there are some errors' do
      let(:described_instance) { described_class.new(hash) }

      before do
        allow(described_instance).to receive(:errors).and_return(['some error'])
      end

      it { expect(described_instance).to be_invalid }
    end
  end
end
