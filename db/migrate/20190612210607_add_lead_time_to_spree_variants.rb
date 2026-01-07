# frozen_string_literal: true

class AddLeadTimeToSpreeVariants < ActiveRecord::Migration[5.2]

  def change
    add_column :spree_variants, :lead_time, :integer
  end
end
