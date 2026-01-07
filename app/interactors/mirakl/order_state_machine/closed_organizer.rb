# frozen_string_literal: true

module Mirakl
  module OrderStateMachine
    class ClosedOrganizer < ApplicationOrganizer
      organize ProcessOrderLineUpdateInteractor,
               BuildTransactionFeePayloadInteractor,
               ::Mirakl::SubmitOrderAdditionalFieldsInteractor
    end
  end
end
