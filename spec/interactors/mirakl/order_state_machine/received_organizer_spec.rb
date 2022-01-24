# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::OrderStateMachine::ReceivedOrganizer, mirakl: true do
  it { expect(described_class.new).to be_a Interactor::Organizer }
  it do
    expect(described_class.organized).to(
      eq [Mirakl::OrderStateMachine::ProcessOrderLineUpdateInteractor,
          Mirakl::OrderStateMachine::Shipped::BuildLateShippingFeePayloadInteractor,
          Mirakl::OrderStateMachine::BuildTransactionFeePayloadInteractor,
          Mirakl::SubmitOrderAdditionalFieldsInteractor]
    )
  end
end
