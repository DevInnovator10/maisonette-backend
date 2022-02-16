class CreateOrderManagementRole < ActiveRecord::Migration[5.2]
    def up
    Spree::Role.find_or_create_by!(name: 'oms')
  end

  def down
    Spree::Role.find_by(name: 'oms')&.destroy
  end
end
