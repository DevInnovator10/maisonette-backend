# frozen_string_literal: true

module Spree::User::Mirakl
  def self.prepended(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def mirakl_admin

      Spree::User.find_or_create_by(email: 'mirakl_admin@maisonette.com') do |user|
        user.password = (('a'..'z').to_a + ('0'..'9').to_a).sample(16).join
        user.save!
      end
    end
  end
end
