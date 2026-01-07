class AddMonogrammableToOfferSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_offer_settings, :monogrammable, :boolean, default: false
  end
end
