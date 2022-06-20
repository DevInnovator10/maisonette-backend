# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::RefundReason::MiraklCodeValidation, type: :model do
  let(:described_class) { Spree::RefundReason }
  let(:reason) { create(:refund_reason, name: 'First reason', mirakl_code: 'abc', active: false) }

  it { is_expected.to have_one(:order_management_entity).class_name('OrderManagement::Reason') }

  context 'when new refund reason is created' do
    context 'when a refund reason with same mirakl code exists' do
      let(:reason1) { create(:refund_reason, name: 'Second reason', mirakl_code: 'abc') }

      before { reason }

      it 'does not create new reason' do
        expect { reason1 }.to raise_error(ActiveRecord::RecordInvalid,
                                          'Validation failed: Mirakl code has already been taken')
      end
    end

    context 'when no refund reason with same mirakl code exists' do
      let(:reason1) { create(:refund_reason, name: 'Second reason', mirakl_code: 'def') }

      before { reason }

      it 'creates new reason' do
        expect { reason1 }.to change { Spree::RefundReason.count }.by(1)
      end
    end
  end

  context 'when existing refund reason is updated' do
    before { reason.update(active: true) }

    it 'updates existing reason' do
      expect(reason.active).to equal(true)
    end
  end
end
