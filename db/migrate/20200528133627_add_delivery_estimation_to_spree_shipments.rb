class AddDeliveryEstimationToSpreeShipments < ActiveRecord::Migration[5.2]
  def up
    add_column :spree_shipments, :delivery_estimation, :string
    Spree::Shipment.where(delivery_estimation: nil).find_each do |shipment|
      shipment.update(delivery_estimation: Spree::DeliveryTimeCalculator.new(shipment).to_s)
    end
  end

  def down
    remove_column :spree_shipments, :delivery_estimation
  end
end
