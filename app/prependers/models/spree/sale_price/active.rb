# frozen_string_literal: true

module Spree::SalePrice::Active
  def active?
    enabled && !start_at&.future? && !end_at&.past?
  end
end
