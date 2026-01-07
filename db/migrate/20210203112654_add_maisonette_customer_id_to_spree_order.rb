# frozen_string_literal: true

class AddMaisonetteCustomerIdToSpreeOrder < ActiveRecord::Migration[5.2]
  def change
    add_reference :spree_orders, :maisonette_customer, foreign_key: true, type: :uuid
  end
end
