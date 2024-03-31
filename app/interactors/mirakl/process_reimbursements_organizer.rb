# frozen_string_literal: true

module Mirakl
  class ProcessReimbursementsOrganizer < ApplicationOrganizer
    organize ProcessReimbursements::RefundsInteractor,
             ProcessReimbursements::CancelationsInteractor,
             ProcessReimbursements::RejectionsInteractor,
             ProcessReimbursements::CheckIfAnyReimbursementsInteractor,
             ProcessReimbursements::CreateReturnFeesInteractor,
             ProcessReimbursements::ActionReimbursementsInteractor,
             ProcessReimbursements::CreateCustomerReturnInteractor,
             Mirakl::BuildReturnFeePayloadInteractor,
             Mirakl::BuildMarkDownCreditPayloadInteractor,
             Mirakl::BuildCostPriceFeePayloadInteractor,
             Mirakl::BuildNoStockFeePayloadInteractor,
             Mirakl::SubmitOrderAdditionalFieldsInteractor
  end
end
