# frozen_string_literal: true

module Spree
  class Wishlist < ApplicationRecord
    belongs_to :user, class_name: 'Spree::User', optional: false
    has_many :wished_products, dependent: :destroy

    after_initialize :set_default_name
    before_validation :set_is_default, if: :new_record?, unless: :default_wishlist_exists

    validates :name, presence: true, uniqueness: { scope: :user_id }
    validates :user, presence: true
    validate :ensure_one_default_wishlist, if: :is_default_changed?, unless: :invalid_user

    before_create :set_access_hash

    accepts_nested_attributes_for :wished_products

    def make_default!
      set_is_default && save!
    end

    private

    def set_default_name
      self.name ||= I18n.t('spree.wishlist.default_name')
    end

    def set_is_default
      self.is_default = true
    end

    def default_wishlist_exists
      self.class.where(user_id: user_id).where.not(id: id).find_by(is_default: true)
    end

    def ensure_one_default_wishlist
      unset_default_wishlists if new_record? || changing_default_wishlist
      errors.add(:is_default, 'Must have one default wishlist') unless is_default
    end

    def invalid_user
      !user
    end

    def unset_default_wishlists
      user.wishlists
          .where.not(id: id)
          .where(is_default: true)
          .update_all(is_default: false) # rubocop:disable Rails/SkipsModelValidations
    end

    def changing_default_wishlist
      !new_record? && default_wishlist_exists
    end

    def set_access_hash
      random_string = SecureRandom.hex(16)
      self.access_hash = Digest::SHA256.hexdigest("--#{user_id}--#{random_string}--#{Time.zone.now}--")
    end
  end
end
