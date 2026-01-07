# frozen_string_literal: true

module Spree::OrderUpdater::UpdateTaxes
  private

  def update_taxes
    if order.completed?
      Rails.logger.info(message: 'skipping tax recalculation, order already complete',
                        order_number: order.number,
                        order_state: order.state,
                        order_completed_at: order.completed_at)

      return
    end

    super
  end
end
