# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::PromotionAction::Advertise, type: :model do
  let(:described_class) { Spree::PromotionAction }

  describe '#after_commit' do
    subject(:update_record!) { promotion_action.update(position: 1) }

    let(:promotion_action) { described_class.create(promotion: promotion) }
    let(:promotion) { build(:promotion) }

    before { promotion_action }

    context 'when promotion is not nil' do
      before do
        allow(promotion).to receive(:touch)
      end

      it 'touches the promotion' do
        update_record!
        expect(promotion).to have_received(:touch)
      end
    end

    context 'when promotion is nil' do
      let(:promotion) { nil }

      it 'does not raise any exception' do
        expect { update_record! }.not_to raise_error
      end
    end
  end
end
