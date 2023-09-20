class AddUniqueIndexNameToSpreePromotionCategories < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_promotion_categories, :name, unique: true
  end
end
