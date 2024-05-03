# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::StoreCredit::Scopes, type: :model do
  let(:described_class) { Spree::StoreCredit }

  describe '.valid' do
    subject { described_class.valid }

    let(:no_invalidated_at) { create :store_credit }
    let(:invalidated) { create :store_credit, invalidated_at: 1.week.ago }
    let(:invalidated_in_future) { create :store_credit, invalidated_at: Time.zone.today + 1.week }

    let(:credits) { [] }

    context 'when there are no credits' do
      it { is_expected.to match_array credits }
    end

    context 'when there are only credits with invalidated date in the past' do
      before { invalidated }

      it { is_expected.to match_array credits }
    end

    context 'when there are credits with no invalidated date' do
      let(:credits) { [no_invalidated_at] }

      before { no_invalidated_at }

      it { is_expected.to match_array credits }
    end

    context 'when there are credits with invalidated date in the future' do
      let(:credits) { [invalidated_in_future] }

      before { invalidated_in_future }

      it { is_expected.to match_array credits }
    end

    context 'when there are credits of all types' do
      let(:credits) { [no_invalidated_at, invalidated_in_future] }

      before { no_invalidated_at && invalidated && invalidated_in_future }

      it { is_expected.to match_array credits }
    end
  end

  describe '.with_remaining_balance' do
    subject { described_class.with_remaining_balance }

    let(:credit_with_balance) { create :store_credit, amount: 15, amount_used: 5, amount_authorized: 5 }
    let(:credit_used) { create :store_credit, amount: 15, amount_used: 15 }
    let(:credit_not_authorized) { create :store_credit, amount: 15, amount_authorized: 15 }

    let(:credits) { [] }

    context 'when there are no store credits' do
      it { is_expected.to match_array credits }
    end

    context 'when there are only used store credits' do
      before { credit_used }

      it { is_expected.to match_array credits }
    end

    context 'when there are only store credits with amount not authorized' do
      before { credit_not_authorized }

      it { is_expected.to match_array credits }
    end

    context 'when there are store credits with positive balance' do
      let(:credits) { [credit_with_balance] }

      before { credit_with_balance }

      it { is_expected.to match_array credits }
    end

    context 'when there are all types of store credits' do
      let(:credits) { [credit_with_balance] }

      before { credit_with_balance && credit_used && credit_not_authorized }

      it { is_expected.to match_array credits }
    end
  end

end
