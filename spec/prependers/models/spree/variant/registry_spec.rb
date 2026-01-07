# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Variant::Registry, type: :model do
  subject { variant.registry? }

  let(:variant) { create(:variant) }
  let(:offer_settings) { create(:offer_settings, registry: false) }
  let(:registry_offer_settings) { create(:offer_settings, registry: is_registry) }
  let(:is_registry) { false }

  before do
    allow(variant).to receive_messages(offer_settings: [offer_settings, registry_offer_settings])
  end

  it { is_expected.to be_falsey }

  context 'when there is one registry variant' do
    let(:is_registry) { true }

    it { is_expected.to be_truthy }
  end
end
