# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::PromotionCode::Advertise, type: :model do
  let(:described_class) { Spree::PromotionCode }

  describe '#after_commit' do
    subject(:update_record!) { promotion_code.update(value: 'CODE') }

    let(:promotion_code) { create(:promotion_code, promotion: promotion) }
    let(:promotion) { build(:promotion) }

    before do
      promotion_code
      allow(promotion).to receive(:touch)
    end

    it 'touches the promotion' do
      update_record!
      expect(promotion).to have_received(:touch)
    end
  end
end
