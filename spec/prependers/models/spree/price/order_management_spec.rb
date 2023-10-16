# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Price::OrderManagement, type: :model do
  let(:described_class) { Spree::Price }

  describe '#external_id' do
    let(:price) { build_stubbed(:price) }
    let(:gid) { price.to_gid_param }

    it 'return an hash' do
      expect(price.external_id).to eq(gid)
    end
  end

  context 'when create', :with_price_sync_entity do
    let(:price) { create(:price) }

    before do
      allow(OrderManagement::PriceBookEntry).to receive(:mark_out_of_sync!)
    end

    it 'marks the order management price as out of sync' do
      price

      expect(OrderManagement::PriceBookEntry).to have_received(:mark_out_of_sync!).with(price).at_least(:once)
    end
  end

  context 'when discard', :with_price_sync_entity do
    let!(:price) { create(:price) }

    before do
      allow(OrderManagement::PriceBookEntry).to receive(:mark_out_of_sync!)
    end

    it 'marks the order management price as out of sync' do
      price.discard

      expect(OrderManagement::PriceBookEntry).to have_received(:mark_out_of_sync!).at_least(:once)
    end
  end
end
