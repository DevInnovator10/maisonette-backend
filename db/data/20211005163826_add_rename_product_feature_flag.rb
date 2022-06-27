class AddRenameProductFeatureFlag < ActiveRecord::Migration[6.0]
  def up
    Flipper[:rename_product].disable unless Flipper[:rename_product].exist?
  end

  def down
    Flipper[:rename_product].disable unless Flipper[:rename_product].exist?
  end
end
