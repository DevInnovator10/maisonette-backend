class AddShippingCarrierCodeToSpreeShipments < ActiveRecord::Migration[5.2]
  def up
    add_column :spree_shipments, :shipping_carrier_code, :string
    add_column :spree_shipments, :override_tracking_url, :string
    # rubocop:disable Rails/SkipsModelValidations
    Spree::ShippingMethod.update_all(tracking_url: 'https://maisonette.narvar.com/maisonette/tracking/:carrier?tracking_numbers=:tracking')
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    remove_column :spree_shipments, :shipping_carrier_code
    remove_column :spree_shipments, :override_tracking_url
  end
end
