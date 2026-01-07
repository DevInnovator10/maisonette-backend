# frozen_string_literal: true

class AddWaiveCustomerFeeToReturnAuthorization < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_return_authorizations, :waive_customer_return_fee, :boolean, default: false, null: false
  end
end
