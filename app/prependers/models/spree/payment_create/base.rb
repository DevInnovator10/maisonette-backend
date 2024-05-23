# frozen_string_literal: true

module Spree::PaymentCreate::Base
  def build_source
    if source_attributes[:braintree_payment_source_id].present?
      existing_source = SolidusPaypalBraintree::Source.joins(:payments)
                                                      .where(spree_payments: { order_id: order.id })
                                                      .find_by(id: source_attributes[:braintree_payment_source_id])
      raise ActiveRecord::RecordNotFound if existing_source.nil?

      build_from_payment_source(existing_source)

    else
      super
    end
  end
end
