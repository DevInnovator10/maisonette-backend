# frozen_string_literal: true

module Spree::Payment::Dispute
  def self.prepended(base)
    base.has_many :disputes,
                  class_name: 'Reporting::Braintree::Dispute',
                  foreign_key: :spree_payment_id,
                  inverse_of: :spree_payment,
                  dependent: :destroy
  end
end
