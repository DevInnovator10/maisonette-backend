# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::RefundCredit::CreateOrganizer do
  it { expect(described_class.new).to be_a Interactor::Organizer }

  it do
    expect(described_class.organized).to(
      eq [OrderManagement::RefundCredit::BraintreeReimbursementInteractor,

          OrderManagement::RefundCredit::AfterpayReimbursementInteractor,
          OrderManagement::RefundCredit::GiftCardReimbursementInteractor,
          OrderManagement::RefundCredit::StoreCreditReimbursementInteractor]
    )
  end
end
