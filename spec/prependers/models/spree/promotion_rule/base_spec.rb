# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::PromotionRule::Base, type: :model do
  describe 'invalidate free_shipping_threshold' do
    subject(:save_promotion) { promotion.save }

    let(:promotion) { create(:promotion, :with_item_total_rule, promotion_category: promotion_category) }

    before do
      allow(Maisonette::Config).to receive(:free_shipping_threshold)
    end

    context 'when promotion is related to free_shipping promotion category' do
      let(:promotion_category) { create(:promotion_category, code: :free_shipping) }

      it 'invalidates the cache' do
        save_promotion

        expect(Maisonette::Config).to have_received(:free_shipping_threshold).with(force_refresh: true).at_least(:once)
      end
    end

    context 'when promotion is not related to free_shipping promotion category' do
      let(:promotion_category) { create(:promotion_category, code: :not_free_shipping) }

      it 'invalidates the cache' do
        save_promotion

        expect(Maisonette::Config).not_to have_received(:free_shipping_threshold)
      end
    end
  end
end
