class ChangeAllArraysToJsonbOnSyndicationProducts < ActiveRecord::Migration[5.2]
  def up

    Syndication::Product.connection.remove_column :syndication_products, :product_type
    Syndication::Product.connection.remove_column :syndication_products, :gender
    Syndication::Product.connection.remove_column :syndication_products, :color
    Syndication::Product.connection.remove_column :syndication_products, :trends
    Syndication::Product.connection.remove_column :syndication_products, :edits
    Syndication::Product.connection.remove_column :syndication_products, :category

    Syndication::Product.connection.add_column :syndication_products, :product_type, :jsonb
    Syndication::Product.connection.add_column :syndication_products, :gender, :jsonb
    Syndication::Product.connection.add_column :syndication_products, :color, :jsonb
    Syndication::Product.connection.add_column :syndication_products, :trends, :jsonb
    Syndication::Product.connection.add_column :syndication_products, :edits, :jsonb
    Syndication::Product.connection.add_column :syndication_products, :category, :jsonb
  end

  def down
    Syndication::Product.connection.remove_column :syndication_products, :product_type
    Syndication::Product.connection.remove_column :syndication_products, :gender
    Syndication::Product.connection.remove_column :syndication_products, :color
    Syndication::Product.connection.remove_column :syndication_products, :trends
    Syndication::Product.connection.remove_column :syndication_products, :edits
    Syndication::Product.connection.remove_column :syndication_products, :category

    Syndication::Product.connection.add_column :syndication_products, :product_type, :string
    Syndication::Product.connection.add_column :syndication_products, :gender, :string
    Syndication::Product.connection.add_column :syndication_products, :color, :string
    Syndication::Product.connection.add_column :syndication_products, :trends, :string
    Syndication::Product.connection.add_column :syndication_products, :edits, :string
    Syndication::Product.connection.add_column :syndication_products, :category, :string
  end
end
