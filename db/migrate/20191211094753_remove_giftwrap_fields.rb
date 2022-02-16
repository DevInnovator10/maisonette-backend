class RemoveGiftwrapFields < ActiveRecord::Migration[5.2]
  def change
    remove_column :maisonette_giftwraps, :message, :string
    remove_column :maisonette_giftwraps, :recipient_email, :string
  end
end
