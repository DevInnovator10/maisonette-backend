# frozen_string_literal: true

class AddUrlOverrideToSpreeTaxons < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_taxons, :url_override, :string
  end
end
