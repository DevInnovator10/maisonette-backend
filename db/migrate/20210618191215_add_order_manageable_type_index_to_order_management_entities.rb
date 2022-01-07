class AddOrderManageableTypeIndexToOrderManagementEntities < ActiveRecord::Migration[5.2]
  def change

    add_index :order_management_entities, :order_manageable_type
  end
end
