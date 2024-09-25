# frozen_string_literal: true

module Maisonette
  module Kustomer
    module Reimbursement
      class CreditPresenter
        def initialize(credit)
          @credit = credit
        end

        def kustomer_payload
          base_attributes.merge(
            'type' => @credit.creditable_type,
            'memo' => @credit.creditable&.memo,
            'reimbursementNumber' => @credit.reimbursement.number
          )
        end

        private

        def base_attributes
          @credit.attributes.extract!('amount')
        end
      end
    end

  end
end
