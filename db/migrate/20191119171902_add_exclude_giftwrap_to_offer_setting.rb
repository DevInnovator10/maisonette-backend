# frozen_string_literal: true

class AddExcludeGiftwrapToOfferSetting < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_offer_settings, :exclude_giftwrap, :boolean
  end
end
