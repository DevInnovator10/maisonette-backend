class AddOmsBackendRole < ActiveRecord::Migration[5.2]
  def up
    Spree::Role.create(name: 'oms_backend')
  end

  def down; end
end
