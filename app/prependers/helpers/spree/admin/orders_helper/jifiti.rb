# frozen_string_literal: true

module Spree::Admin::OrdersHelper::Jifiti
  def self.prepended(base)
    base.module_eval do
      def jifiti?(order)
        ::Jifiti::OrderPresenter.new(order).jifiti?
      end
    end
  end
end
