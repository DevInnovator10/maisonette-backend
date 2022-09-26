# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Product::Registry, type: :model do
  subject { product.registry? }

  let(:product) { create(:product) }
  let(:variant) { create(:variant) }
  let(:registry_variant) { create(:variant) }
  let(:is_registry) { false }

  before do
    allow(registry_variant).to receive(:registry?).and_return(is_registry)
    allow(product).to receive_messages(variants: [variant, registry_variant])
  end

  it { is_expected.to be_falsey }

  context 'when there is one registry variant' do
    let(:is_registry) { true }

    it { is_expected.to be_truthy }
  end
end
