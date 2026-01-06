# frozen_string_literal: true

class AddAddFlairToSpreeTaxons < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_taxons, :add_flair, :boolean, default: false
  end
end
