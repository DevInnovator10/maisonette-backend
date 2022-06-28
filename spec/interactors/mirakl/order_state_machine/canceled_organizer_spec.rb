# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::OrderStateMachine::CanceledOrganizer, mirakl: true do
  it { expect(described_class.new).to be_a Interactor::Organizer }
  it do
    expect(described_class.organized).to(
      eq [Mirakl::OrderStateMachine::ProcessOrderLineUpdateInteractor,
          Mirakl::OrderStateMachine::SendOrderRejectionCancelationEmailInteractor,
          Mirakl::BuildOrderFeePayloadInteractor,
          Mirakl::SubmitOrderAdditionalFieldsInteractor]
    )
  end
end
