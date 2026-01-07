# frozen_string_literal: true

class MoveFinalSaleOnOfferSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_offer_settings, :final_sale, :boolean, default: false

    remove_column :spree_prices, :final_sale, :boolean, default: false
  end
end
