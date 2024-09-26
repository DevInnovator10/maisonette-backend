# frozen_string_literal: true

module Spree::Order::Kustomer
  def self.prepended(base)
    base.has_one :kustomer_order,
                 as: :kustomerable,
                 class_name: 'Maisonette::Kustomer::Order',
                 dependent: :nullify
    base.has_one :kustomer_customer,
                 as: :kustomerable,
                 class_name: 'Maisonette::Kustomer::Customer',
                 dependent: :nullify

    base.state_machine do
      after_transition to: %i[complete], do: :mark_out_of_sync
    end

    base.after_commit :mark_out_of_sync, on: :update
  end

  def mark_out_of_sync(*_args)
    return unless completed?

    mark_order_out_of_sync
    mark_customer_out_of_sync
  end

  private

  def mark_order_out_of_sync
    Maisonette::Kustomer::Order.mark_out_of_sync(self)
  end

  def mark_customer_out_of_sync
    Maisonette::Kustomer::Customer.mark_out_of_sync(self)
  end
end
