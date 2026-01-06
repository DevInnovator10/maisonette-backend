# frozen_string_literal: true

module Mirakl
  class BackfillReturnFeeOrganizer < ApplicationOrganizer
    organize Mirakl::BackfillReturnFeeForVendorsInteractor,
             Mirakl::BuildReturnFeePayloadInteractor,
             Mirakl::SubmitOrderAdditionalFieldsInteractor
  end
end
