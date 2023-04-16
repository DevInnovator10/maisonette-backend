# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Product::OrderManagement, type: :model do
  let(:described_class) { Spree::Product }
  let(:offer_settings) { create(:offer_settings) }
  let(:product) { offer_settings.variant.product }

  describe '#after_commit' do
    subject(:save_product) { product.save! }

    before do
      allow(OrderManagement::Product).to receive(:mark_out_of_sync!).at_least(:once)
    end

    it 'marks the order management product as out of sync' do
      save_product

      expect(OrderManagement::Product).to have_received(:mark_out_of_sync!).at_least(:once)
    end
  end
end
