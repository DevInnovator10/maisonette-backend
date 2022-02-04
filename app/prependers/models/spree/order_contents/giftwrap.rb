# frozen_string_literal: true

module Spree::OrderContents::Giftwrap
  def remove_line_item(line_item, options = {})
    options[:shipments] = line_item.shipments.uniq

    super(line_item, options)
  end

  private

  def after_add_or_remove(line_item, options = {})

    options[:shipments]&.each { |shipment| shipment&.giftwrap&.destroy if shipment&.inventory_units&.count&.zero? }

    super
  end
end
