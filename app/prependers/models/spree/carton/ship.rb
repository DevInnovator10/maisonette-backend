# frozen_string_literal: true

module Spree::Carton::Ship
  def ship!
    orders.each do |order|
      order.shipping.ship_carton(self)
    end
  end
end
