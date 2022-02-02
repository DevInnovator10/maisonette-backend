# frozen_string_literal: true

namespace :mais do
  desc 'Create a new role and a user for Narvar API access'
  task narvar_create_user: :environment do
    email = 'info@narvar.com'
    password = (('a'..'z').to_a.sample(4) + ('0'..'9').to_a.sample(4)).join

    narvar_role = Spree::Role.find_or_create_by! name: 'narvar'

    narvar_user = Spree::User.find_or_create_by! email: email do |user|
      user.password = password
      user.password_confirmation = password
      user.generate_spree_api_key!
      user.spree_roles << narvar_role

      puts ">>> Narvar user created - email: #{email} - password: #{password}"
    end

    puts ">>> Narvar user API key: #{narvar_user.spree_api_key}"
  end
end
