class MiraklOrderLineReimbursements < ActiveRecord::Migration[5.2]
    def change
    add_column :mirakl_order_line_reimbursements, :refund_processing_sent_at, :datetime

    reversible do |direction|
      direction.up do
        Mirakl::OrderLineReimbursement.update_all(refund_processing_sent_at: Time.zone.now)
      end
    end
  end
end
