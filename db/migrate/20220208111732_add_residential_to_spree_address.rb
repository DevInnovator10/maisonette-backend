class AddResidentialToSpreeAddress < ActiveRecord::Migration[6.0]

  def change
    add_column :spree_addresses, :residential, :boolean
  end
end
