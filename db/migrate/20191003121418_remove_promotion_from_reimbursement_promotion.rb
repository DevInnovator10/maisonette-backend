# frozen_string_literal: true

class RemovePromotionFromReimbursementPromotion < ActiveRecord::Migration[5.2]
  def change
    remove_column :spree_reimbursement_promotions, :promotion_id, :bigint
  end
end
