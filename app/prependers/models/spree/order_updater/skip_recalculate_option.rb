# frozen_string_literal: true

module Spree::OrderUpdater::SkipRecalculateOption
  def self.prepended(base)
    base.attr_accessor :skip_recalculate
  end

  private

  def update_shipment_amounts
    return if skip_recalculate

    super
  end

  def update_totals
    return if skip_recalculate

    super
  end
end
