# frozen_string_literal: true

module Admin
    class ShipmentsEditSection < SitePrism::Section
    class StockItems < SitePrism::Section
      element :split_button, 'td.actions button.split-item'
      element :delete_button, 'td.actions button.delete-item'
    end

    sections :items, StockItems, 'tr.stock-item'

    def find_item(name)
      items.find { |l| l.text.match(name) }.tap do |l|
        yield(l) if block_given?
      end
    end
  end
end
