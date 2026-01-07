# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Kustomer::RefundPresenter do
  describe '#kustomer_payload' do
    subject { described_class.new(refund).kustomer_payload }

    let(:refund) { create(:refund, reimbursement: reimbursement) }
    let(:reimbursement) { create(:reimbursement) }

    it do
      is_expected.to match hash_including(
        'amount' => refund.amount,
        'reimbursementNumber' => reimbursement.number,
        'refundReason' => Spree::RefundReason.find(refund.refund_reason_id).name
      )
    end

    context 'when refund_reason is not found' do
      before { Spree::RefundReason.where(id: refund.refund_reason_id).delete_all }

      it 'return refundReason as nil' do
        is_expected.to match hash_including(
          'refundReason' => nil
        )
      end
    end
  end
end
