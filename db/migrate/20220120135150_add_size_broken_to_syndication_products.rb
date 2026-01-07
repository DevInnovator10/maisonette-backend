class AddSizeBrokenToSyndicationProducts < ActiveRecord::Migration[6.0]
  def change
    Syndication::Product.connection.add_column :syndication_products, :size_broken, :boolean
  end
end
