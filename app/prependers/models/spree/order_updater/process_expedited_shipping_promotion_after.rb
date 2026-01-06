# frozen_string_literal: true

module Spree::OrderUpdater::ProcessExpeditedShippingPromotionAfter
  private

  def update_item_promotions
    update_line_item_promotions
    update_shipment_promotions
  end

  def update_line_item_promotions
    line_items.each do |item|
      promotion_adjustments = item.adjustments.select(&:promotion?)

      process_adjustments(promotion_adjustments)

      item.promo_total = promotion_adjustments.select(&:eligible?).sum(&:amount)
    end
  end

  def update_shipment_promotions
    shipments.each do |item|
      adjustments = adjustments_for_not_expedited_shipment(item)
      process_adjustments(adjustments)
    end

    shipments.each do |item|
      adjustments = adjustments_for_expedited_shipment(item)
      process_adjustments(adjustments)

      promotion_adjustments = item.adjustments.select(&:promotion?)
      item.promo_total = promotion_adjustments.select(&:eligible?).sum(&:amount)
    end
  end

  def adjustments_for_not_expedited_shipment(item)
    item.adjustments
        .select(&:promotion?)
        .reject do |adjustment|
          adjustment.source.is_a? Spree::Promotion::Actions::DetractOtherShippingCost
        end
  end

  def adjustments_for_expedited_shipment(item)
    item.adjustments
        .select(&:promotion?)
        .select do |adjustment|
          adjustment.source.is_a? Spree::Promotion::Actions::DetractOtherShippingCost
        end
  end

  def process_adjustments(adjustments)
    adjustments.each(&:recalculate)
    Spree::Config.promotion_chooser_class.new(adjustments).update
  end
end
