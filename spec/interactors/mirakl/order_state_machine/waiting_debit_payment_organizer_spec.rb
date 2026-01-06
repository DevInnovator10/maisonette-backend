# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::OrderStateMachine::WaitingDebitPaymentOrganizer, mirakl: true do
  it { expect(described_class.new).to be_a Interactor::Organizer }
  it do
    expect(described_class.organized).to(
      eq [Mirakl::OrderStateMachine::WaitingDebitPayment::AcceptDebitPaymentInteractor,
          Mirakl::OrderStateMachine::ProcessOrderLineUpdateInteractor,
          Mirakl::OrderStateMachine::SendOrderRejectionCancelationEmailInteractor,

          Mirakl::OrderStateMachine::WaitingDebitPayment::SendPackingSlipAsyncInteractor,
          Mirakl::Easypost::SendLabelsOrganizer,
          Mirakl::OrderStateMachine::WaitingDebitPayment::BuildGiftWrapVendorFeePayloadInteractor,
          Mirakl::OrderStateMachine::WaitingDebitPayment::BuildDropshipSurchargePayloadInteractor,
          ::Mirakl::SubmitOrderAdditionalFieldsInteractor]
    )
  end
end
