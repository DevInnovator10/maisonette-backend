# frozen_string_literal: true

namespace :jifiti do
  desc 'Create a new role and a user for Jifiti'
  task create_role_and_user: :environment do
    role = Spree::Role.find_or_create_by!(name: 'jifiti')
    Spree::User.with_deleted.find_or_create_by!(email: 'jifiti@maisonette.com') do |user|
      user.deleted_at = nil
      user.password = SecureRandom.hex(8)
      user.spree_roles << role
      user.generate_spree_api_key! unless user.spree_api_key
      puts "created #{user.email}"
    end
  end
end
