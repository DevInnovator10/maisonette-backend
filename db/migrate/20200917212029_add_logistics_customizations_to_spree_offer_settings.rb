class AddLogisticsCustomizationsToSpreeOfferSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_offer_settings, :logistics_customizations, :jsonb, default: {}
  end
end
