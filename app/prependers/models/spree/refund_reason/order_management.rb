# frozen_string_literal: true

module Spree::RefundReason::OrderManagement
  def self.prepended(base)
    base.has_one :order_management_entity, as: :order_manageable, class_name: 'OrderManagement::Reason'

    base.after_commit :mark_out_of_sync!
  end

  def mark_out_of_sync!
    ::OrderManagement::Reason.mark_out_of_sync!(self)
  end
end
