# frozen_string_literal: true

module Spree::Order::Recalculate
  include LoggingHelper

  def recalculate
    log_event(:info, "Recalculating Spree Order: #{number} - Order State: #{state}\nFrom: \n#{caller}")

    super
  end
end
