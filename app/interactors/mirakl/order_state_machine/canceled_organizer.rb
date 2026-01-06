# frozen_string_literal: true

module Mirakl
  module OrderStateMachine
    class CanceledOrganizer < ApplicationOrganizer
      organize ProcessOrderLineUpdateInteractor,
               SendOrderRejectionCancelationEmailInteractor,
               ::Mirakl::BuildOrderFeePayloadInteractor,
               ::Mirakl::SubmitOrderAdditionalFieldsInteractor
    end
  end
end
