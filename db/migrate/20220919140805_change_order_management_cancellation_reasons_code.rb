class ChangeOrderManagementCancellationReasonsCode < ActiveRecord::Migration[6.0]
  def change
    change_column_null :order_management_cancellation_reasons, :code, true
    change_column_null :order_management_cancellation_reasons, :mirakl_code, false

  end
end
