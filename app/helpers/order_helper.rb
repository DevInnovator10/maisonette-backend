# frozen_string_literal: true

module OrderHelper
  def monogram_color_display_name(line_item)
    selected_color = line_item.monogram.customization.dig(:color, :name)
    offer_settings = line_item.variant.offer_settings_for_vendor(line_item.vendor)
    return selected_color if offer_settings.blank?

    color_options = offer_settings.monogram_customizations.dig(:colors)
    color_name = color_options&.detect { |color_pair| color_pair['name'] == selected_color + ' Title' }&.dig(:value)
    color_name || selected_color
  end

  def order_subtotals(order)
    subtotals.clear

    add_base_subtotals(order)
    add_line_item_adjustments(order)
    add_tax(order)
    add_shipments(order)
    add_miscellaneous(order)
    add_giftwrap_totals(order)

    subtotals
  end

  private

  def subtotals
    @subtotals ||= [] # rubocop:disable Rails/HelperInstanceVariable
  end

  def add_base_subtotals(order)
    subtotals << {
      label: 'Subtotal',
      info: '(excludes shipping and taxes)',
      value: order.display_item_total
    }
  end

  def add_line_item_adjustments(order)
    return if order.line_item_adjustments.nonzero.empty?

    order.line_item_adjustments.nonzero.promotion.eligible.group_by(&:label).each do |label, adjustments|
      subtotals << {
        label: label,
        value: Spree::Money.new(adjustments.sum(&:amount), currency: order.currency).to_s
      }
    end
  end

  def add_tax(order)
    return if order.all_adjustments.tax.empty?

    order.all_adjustments.tax.group_by(&:label).each_value do |adjustments|
      subtotals << {
        label: 'Tax',
        value: Spree::Money.new(adjustments.sum(&:amount), currency: order.currency).to_s
      }
    end
  end

  def add_shipments(order)
    eligible_adjustments = order.shipment_adjustments.eligible
    shipments_adjustment_amount = eligible_adjustments.present? ? eligible_adjustments.sum(:amount) : 0
    ship_total_with_adjustments = order.ship_total + shipments_adjustment_amount

    return if ship_total_with_adjustments <= 0

    subtotals << {
      label: 'Shipping',
      value: Spree::Money.new(ship_total_with_adjustments, currency: order.currency).to_s
    }
  end

  def add_miscellaneous(order)
    return if order.adjustments.nonzero.eligible.empty?

    order.adjustments.nonzero.non_tax.eligible.each do |adjustment|
      next if adjustment.label.downcase.include?('ship')

      subtotals << {
        label: adjustment.label,
        value: Spree::Money.new(adjustment.amount, currency: order.currency).to_s
      }
    end
  end

  def add_giftwrap_totals(order)
    return unless order.has_giftwrap?

    subtotals << {
      label: 'Gift Wrapping',
      value: Spree::Money.new(order.giftwrap_total, currency: order.currency).to_s
    }
  end
end
