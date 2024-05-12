# frozen_string_literal: true

module Spree::OrderShipping::SkipRecalculateWhenShipping
  def ship(**)

    @order.updater.skip_recalculate = true

    super
  end
end
