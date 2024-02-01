class CreateSpreeGiftCards < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_gift_cards do |t|
      t.string :name
      t.decimal :balance, precision: 10, scale: 2, default: "0.0"
      t.string :currency
      t.decimal :original_amount, precision: 10, scale: 2, default: "0.0"
      t.belongs_to :promotion_code
      t.belongs_to :line_item
      t.string :state, null: false, default: 'allocated'
      t.string :recipient_email
      t.string :recipient_name
      t.string :purchaser_name
      t.datetime :send_email_at
      t.text :gift_message
      t.boolean :redeemable, default: false
      t.datetime :sent_at

      t.timestamps
    end
  end
end
