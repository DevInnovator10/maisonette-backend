# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Promotion::Base, type: :model do
  describe '.free_shipping_category?' do
    subject { promotion.free_shipping_category? }

    let(:promotion) { build_stubbed(:promotion, promotion_category: promotion_category) }

    context 'when promotion is related to free_shipping promotion category' do
      let(:promotion_category) { build_stubbed(:promotion_category, code: :free_shipping) }

      it { is_expected.to be_truthy }
    end

    context 'when promotion is not related to free_shipping promotion category' do
      let(:promotion_category) { build_stubbed(:promotion_category, code: :not_free_shipping) }

      it { is_expected.to be_falsey }
    end
  end
end
