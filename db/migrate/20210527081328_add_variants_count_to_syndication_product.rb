class AddVariantsCountToSyndicationProduct < ActiveRecord::Migration[5.2]
  def change
    Syndication::Product.connection.add_column :syndication_products, :variants_count, :integer

  end
end
