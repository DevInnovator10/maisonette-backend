# frozen_string_literal: true

module Maisonette
  class Fee < ApplicationRecord
    belongs_to :spree_return_authorization, class_name: 'Spree::ReturnAuthorization', optional: true

    belongs_to :spree_reimbursement, class_name: 'Spree::Reimbursement', optional: true

    enum fee_type: {
      return: 1,
      restock: 2
    }
  end
end
