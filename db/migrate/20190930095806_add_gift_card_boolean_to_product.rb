class AddGiftCardBooleanToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :gift_card, :boolean, default: false
  end
end
