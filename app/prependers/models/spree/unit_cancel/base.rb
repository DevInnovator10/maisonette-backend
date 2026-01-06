# frozen_string_literal: true

module Spree::UnitCancel::Base

  def self.prepended(base)
    base.belongs_to :reimbursement, optional: true
  end
end
