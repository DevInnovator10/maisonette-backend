# frozen_string_literal: true

module Spree
  module Stock
    class LineItemAvailability < Availability
      def initialize(line_items:, stock_locations: Spree::StockLocation.active)
        @variants = line_items.map(&:variant).uniq

        @line_items = line_items
        @line_items_map = line_items.index_by { |li| [li.variant_id, li.vendor&.stock_location&.id, li.monogram&.id] }
        @stock_locations = stock_locations
      end

      def on_hand_by_stock_location_id
        counts_on_hand.to_a.group_by do |(_, stock_location_id), _|
          stock_location_id
        end.transform_values do |values|
          Spree::LineItemStockQuantities.new(line_item_stock_quantity(values))
        end
      end

      def backorderable_by_stock_location_id
        backorderables.group_by(&:second).transform_values do |variant_stock_locations|
          Spree::LineItemStockQuantities.new(line_item_backorderable_stock_quantity(variant_stock_locations))
        end
      end

      private

      def line_item_backorderable_stock_quantity(variant_stock_locations)
        @line_items_map.map do |line_item_map|
          variant_id, stock_location_id, _monogram_id = line_item_map[0]
          line_item = line_item_map[1]

          inventory_on_hand = variant_stock_locations.detect do |inventory_on_hand_group|
            inventory_on_hand_group == [variant_id, stock_location_id]
          end
          next if inventory_on_hand.nil?

          [line_item, Float::INFINITY]
        end.compact.to_h
      end

      def line_item_stock_quantity(inventory_on_hand_grouped_by_stock_location)
        @line_items_map.map do |line_item_map|
          variant_id, stock_location_id, _monogram_id = line_item_map[0]
          line_item = line_item_map[1]

          inventory_on_hand = inventory_on_hand_grouped_by_stock_location.detect do |inventory_on_hand_group|
            inventory_on_hand_group[0] == [variant_id, stock_location_id]
          end
          next if inventory_on_hand.nil?

          count = inventory_on_hand[1]
          count = Float::INFINITY if !line_item.variant.should_track_inventory?
          count = 0 if count.negative?
          [line_item, count]
        end.compact.to_h
      end

      def stock_item_scope
        Spree::StockItem
          .joins(:stock_location, variant: :prices)
          .where('spree_prices.vendor_id = spree_stock_locations.vendor_id')
          .where(variant_id: @variants, stock_location_id: @stock_locations)
      end
    end
  end
end
