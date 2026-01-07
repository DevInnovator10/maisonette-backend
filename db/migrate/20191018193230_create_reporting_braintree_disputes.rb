class CreateReportingBraintreeDisputes < ActiveRecord::Migration[5.2]
  def change
    create_table :reporting_braintree_disputes do |t|
      t.belongs_to :spree_payment
      t.string :transaction_code
      t.string :reason
      t.string :kind
      t.string :status
      t.float :amount
      t.string :case_number, index: true
      t.string :braintree_dispute_id, index: true, unique: true
      t.string :dispute_payload
      t.string :spree_order_number, index: true
      t.datetime :received_date
    end
  end
end
