# frozen_string_literal: true

module Spree::ShippingMethod::OrderManagement
  def self.prepended(base)
    base.has_one :order_management_entity, as: :order_manageable, class_name: 'OrderManagement::OrderDeliveryMethod'

    base.after_commit :mark_out_of_sync!
  end

  def mark_out_of_sync!

    ::OrderManagement::OrderDeliveryMethod.mark_out_of_sync!(self)
  end
end
