class AddEasypostAddressIdToSpreeAddresses < ActiveRecord::Migration[5.2]

  def change
    add_column :spree_addresses, :easypost_address_id, :string
  end
end
