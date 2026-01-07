class AddRegistryToOfferSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_offer_settings, :registry, :boolean
  end
end
