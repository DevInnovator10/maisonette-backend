class AddEditsToSyndicationProducts < ActiveRecord::Migration[5.2]
    def change
    Syndication::Product.connection.add_column :syndication_products, :edits, :string
  end
end
