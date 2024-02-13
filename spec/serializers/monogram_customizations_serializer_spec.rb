# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonogramCustomizationsSerializer do
  describe '.dump' do
    subject { described_class.dump(hash) }

    context 'when the argument is a hash' do
      let(:hash) { { 'key' => 'value' } }

      it { is_expected.to eq '{"key":"value"}' }
    end
  end

  describe '.dump' do
    subject { described_class.load(string) }

    context 'when the argument is nil' do
      let(:string) {}

      it { is_expected.to be_an_instance_of Spree::OfferSettings::MonogramCustomizations }

      it { is_expected.to eq({}) }
    end

    context 'when the argument is a valid JSON hash' do
      let(:string) { '{"key":"value"}' }

      it { is_expected.to be_an_instance_of Spree::OfferSettings::MonogramCustomizations }

      it { is_expected.to eq('key' => 'value') }
    end
  end
end
