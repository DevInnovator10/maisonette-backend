class CreateSpreeReimbursementPromotions < ActiveRecord::Migration[5.2]
  def change

    create_table :spree_reimbursement_promotions do |t|
      t.decimal :amount, precision: 10, scale: 2, default: '0.0', null: false
      t.integer :reimbursement_id
      t.belongs_to :promotion

      t.timestamps
    end
  end
end
