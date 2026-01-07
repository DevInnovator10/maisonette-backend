# frozen_string_literal: true

class RemoveBrandAllAndBrandDiscoverFromSpreeTaxons < ActiveRecord::Migration[5.2]
  def change
    remove_column :spree_taxons, :brand_discover
    remove_column :spree_taxons, :brand_all
  end
end
