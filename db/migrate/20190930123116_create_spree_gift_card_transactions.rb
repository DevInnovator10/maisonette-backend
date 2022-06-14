class CreateSpreeGiftCardTransactions < ActiveRecord::Migration[5.2]
    def change
    create_table :spree_gift_card_transactions do |t|
      t.decimal :amount, precision: 10, scale: 2, default: "0.0", null: false
      t.string :action
      t.string :currency
      t.belongs_to :gift_card
      t.belongs_to :order
      t.timestamps
    end
  end
end
