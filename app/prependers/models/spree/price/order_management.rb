# frozen_string_literal: true

module Spree::Price::OrderManagement
  def self.prepended(base)
    base.after_create :mark_out_of_sync!
    base.after_discard :mark_out_of_sync!
  end

  def external_id
    to_gid_param
  end

  def mark_out_of_sync!
    OrderManagement::PriceBookEntry.mark_out_of_sync!(self)
  end
end
