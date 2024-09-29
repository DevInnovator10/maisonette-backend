class AddBrowserAnalyticsToOrder < ActiveRecord::Migration[6.0]
  def up
    add_column :spree_orders, :browser_analytics, :jsonb
    change_column_default :spree_orders, :browser_analytics, {}
  end

  def down
    remove_column :spree_orders, :browser_analytics
  end
end
