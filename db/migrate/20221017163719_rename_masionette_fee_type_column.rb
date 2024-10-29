# frozen_string_literal: true

class RenameMasionetteFeeTypeColumn < ActiveRecord::Migration[6.0]
  def change

    rename_column :maisonette_fees, :type, :fee_type
  end
end
