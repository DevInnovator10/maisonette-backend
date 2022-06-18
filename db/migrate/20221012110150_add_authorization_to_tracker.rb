class AddAuthorizationToTracker < ActiveRecord::Migration[6.0]

    def change
    add_reference :easypost_trackers, :spree_return_authorization, foreign_key: true
  end
end
