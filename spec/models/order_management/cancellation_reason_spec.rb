# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::CancellationReason, type: :model do
  let(:described_class) { OrderManagement::CancellationReason }

  describe 'associations' do
    it { is_expected.to have_one(:order_management_entity).class_name('OrderManagement::Reason') }
  end

  describe 'validations' do
    subject { build :oms_cancellation_reason, code: 'WRONG_ITEM', name: 'wrong item' }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:mirakl_code) }
    it { is_expected.to validate_uniqueness_of(:mirakl_code) }
  end

  describe '.order_management_object_name' do
    subject(:order_management_object_name) { described_class.order_management_object_name }

    it 'returns correct object name' do
      is_expected.to eq 'CancellationReason'
    end
  end

  context 'when on commit' do
    let(:cancellation_reason) { create(:oms_cancellation_reason) }

    before do
      allow(OrderManagement::Reason).to receive(:mark_out_of_sync!)
    end

    it 'marks the order management reason as out of sync' do
      expect(OrderManagement::Reason).to have_received(:mark_out_of_sync!).with(cancellation_reason).once
    end
  end
end
