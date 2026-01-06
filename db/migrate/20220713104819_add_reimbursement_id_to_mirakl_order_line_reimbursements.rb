class AddReimbursementIdToMiraklOrderLineReimbursements < ActiveRecord::Migration[6.0]
  def up
    add_belongs_to :mirakl_order_line_reimbursements, :reimbursement, index: false

    add_index :mirakl_order_line_reimbursements, [:reimbursement_id],
              name: 'index_mirakl_order_line_reimbursements_on_reimbursement_id'

    execute <<-SQL
      UPDATE mirakl_order_line_reimbursements
      SET reimbursement_id = spree_reimbursements.id
      FROM spree_reimbursements
      WHERE mirakl_order_line_reimbursements.id = spree_reimbursements.mirakl_order_line_reimbursement_id
    SQL

    remove_index :spree_reimbursements, name: 'index_spree_reimbursements_on_mirakl_order_line_reimb_id'

    remove_column :spree_reimbursements, :mirakl_order_line_reimbursement_id
  end

  def down
    add_belongs_to :spree_reimbursements, :mirakl_order_line_reimbursement, index: false

    add_index :spree_reimbursements, [:mirakl_order_line_reimbursement_id],
              name: 'index_spree_reimbursements_on_mirakl_order_line_reimb_id'

    execute <<-SQL
      UPDATE spree_reimbursements
      SET mirakl_order_line_reimbursement_id = mirakl_order_line_reimbursements.id
      FROM mirakl_order_line_reimbursements
      WHERE spree_reimbursements.id = mirakl_order_line_reimbursements.reimbursement_id
    SQL

    remove_index :mirakl_order_line_reimbursements, name: 'index_mirakl_order_line_reimbursements_on_reimbursement_id'

    remove_column :mirakl_order_line_reimbursements, :reimbursement_id
  end
end
