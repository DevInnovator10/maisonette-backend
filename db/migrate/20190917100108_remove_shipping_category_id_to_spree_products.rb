# frozen_string_literal: true

class RemoveShippingCategoryIdToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    remove_column :spree_products, :shipping_category_id, :integer
  end

  def migrate(direction)
    super

    return if direction != :down

    Spree::Product.includes(:variants_including_master).find_each do |product|
      product.update_column( # rubocop:disable Rails/SkipsModelValidations
        :shipping_category_id, product.variants_including_master.first.shipping_category_id
      )
    end
  end
end
