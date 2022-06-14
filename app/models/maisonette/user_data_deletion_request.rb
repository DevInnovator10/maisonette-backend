# frozen_string_literal: true

module Maisonette
  class UserDataDeletionRequest < ApplicationRecord
    belongs_to :user, class_name: 'Spree::User'

    enum status: {
      pending: 1,
      user_deactivated: 2,
      user_data_obfuscated: 3,
      failed: 4
    }

    validates :user, :email, :status, presence: true
    validates :user_id, uniqueness: true
  end
end
