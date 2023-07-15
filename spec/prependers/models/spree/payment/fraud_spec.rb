# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Payment::Fraud, type: :model do
    describe '#update_forter' do
    let(:payment) { create(:payment, state: :processing) }
    let(:order) { payment.order }
    let(:feature_flag) { true }

    before do
      allow(Forter::SendOrderStatusUpdateWorker).to receive_messages(perform_async: true)
      Flipper[:forter_fraud_validation].enable if feature_flag

      payment.failure!
    end

    it 'calls Forter::SendOrderStatusUpdateWorker' do
      expect(Forter::SendOrderStatusUpdateWorker).to(
        have_received(:perform_async).with(order.number, payment.id).once
      )
    end
  end
end
