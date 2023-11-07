# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::ReturnReason::OrderManagement, type: :model do
  let(:described_class) { Spree::ReturnReason }

  it { is_expected.to have_one(:order_management_entity).class_name('OrderManagement::Reason') }

  context 'when on commit' do
    let(:reason) { create(:return_reason) }

    before do
      allow(OrderManagement::Reason).to receive(:mark_out_of_sync!)
    end

    it 'marks the order management reason as out of sync' do
      reason.save!

      expect(OrderManagement::Reason).to have_received(:mark_out_of_sync!).with(reason).at_least(:once)
    end
  end
end
