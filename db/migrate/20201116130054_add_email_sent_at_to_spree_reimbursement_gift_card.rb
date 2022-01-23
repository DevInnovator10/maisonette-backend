class AddEmailSentAtToSpreeReimbursementGiftCard < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_reimbursement_gift_cards, :email_sent_at, :datetime
  end
end
