# frozen_string_literal: true

class AddReusableToSolidusPaypalBraintreeSources < ActiveRecord::Migration[5.2]
    def change
    add_column :solidus_paypal_braintree_sources, :reusable, :boolean, null: false, default: true
  end
end
