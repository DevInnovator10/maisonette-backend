class AddDefaultToSpreeOfferSettingsMonogramMaxTextLength < ActiveRecord::Migration[5.2]
  def up
    remove_column :spree_line_item_monograms, :max_text_length, :integer
    ActiveRecord::Base.transaction do

      Spree::OfferSettings.find_each do |offer_settings|
        next if offer_settings.monogram_max_text_length.present?

        offer_settings.update_column(:monogram_max_text_length, 20)
      end
    end
    change_column :spree_offer_settings, :monogram_max_text_length, :integer, default: 20, null: false
  end

  def down
    add_column :spree_line_item_monograms, :max_text_length, :integer, null: true
    change_column :spree_offer_settings, :monogram_max_text_length, :integer, null: true
  end
end
