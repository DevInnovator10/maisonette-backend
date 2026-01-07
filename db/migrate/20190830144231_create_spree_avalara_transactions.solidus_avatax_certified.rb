# frozen_string_literal: true
# This migration comes from solidus_avatax_certified (originally 20160624154205)

class CreateSpreeAvalaraTransactions < SolidusSupport::Migration[4.2]
  def change

    create_table :spree_avalara_transactions do |t|
      t.references :order, index: true

      t.timestamps null: false
    end
  end
end
