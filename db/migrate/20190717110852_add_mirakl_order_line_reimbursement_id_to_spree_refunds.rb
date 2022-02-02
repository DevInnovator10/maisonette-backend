class AddMiraklOrderLineReimbursementIdToSpreeRefunds < ActiveRecord::Migration[5.2]
  def change

    add_belongs_to :spree_refunds, :mirakl_order_line_reimbursement, index: true
  end
end
