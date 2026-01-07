# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Refund::Base, type: :model do
  let(:described_class) { Spree::Refund }
  let(:refund) { described_class.new(transaction_id: '1_') }

  describe '#store_credit_refund' do
    let(:reimbursement) { Spree::Reimbursement.new }

    it 'returns false if no reimbursement' do
      allow(refund).to receive(:reimbursement).and_return(nil)
      expect(refund.store_credit_refund?).to be false
    end

    it 'returns false if reimbursement has no credits' do
      allow(refund).to receive(:reimbursement).and_return(reimbursement)
      allow(reimbursement.credits).to receive(:empty?).and_return true
      expect(refund.store_credit_refund?).to be false
    end

    it 'returns false if reimbursement has no credits that are creditable' do
      allow(refund).to receive(:reimbursement).and_return(reimbursement)
      allow(reimbursement.credits).to receive(:empty?).and_return false
      allow(reimbursement.credits).to receive(:any?).and_return false
      expect(refund.store_credit_refund?).to be false
    end

    it 'returns true if reimbursement has credits that are creditable' do
      allow(refund).to receive(:reimbursement).and_return(reimbursement)
      allow(reimbursement.credits).to receive(:empty?).and_return false
      allow(reimbursement.credits).to receive(:any?).and_return true
      expect(refund.store_credit_refund?).to be true
    end
  end

  describe '#reimbursement_creditable_match?' do
    let(:creditable) { instance_double('Spree::StoreCredit') }

    it 'returns false if no creditable' do
      expect(refund.reimbursement_creditable_match?(nil)).to be false
    end

    it 'returns false if creditable is not a StoreCredit' do
      allow(creditable).to receive(:is_a?).and_return false
      expect(refund.reimbursement_creditable_match?(creditable)).to be false
    end

    it 'returns false if creditable_amount is not the same as the refund amount' do
      allow(creditable).to receive(:is_a?).and_return true
      allow(creditable).to receive(:amount).and_return 100
      allow(refund).to receive(:amount).and_return 200

      expect(refund.reimbursement_creditable_match?(creditable)).to be false
    end

    it 'returns true if creditable_amount and transaction ID matches' do
      allow(creditable).to receive(:is_a?).and_return true
      allow(creditable).to receive(:amount).and_return 100
      allow(refund).to receive(:amount).and_return 100
      allow(creditable).to receive(:id).and_return 1

      expect(refund.reimbursement_creditable_match?(creditable)).to be true
    end
  end
end
