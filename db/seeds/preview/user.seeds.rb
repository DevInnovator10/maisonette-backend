# frozen_string_literal: true

addresses = Spree::Address.all.to_a

20.times do
  user = Spree::User.new(email: FFaker::Internet.email, password: 'password')
  notify_if_saved(user, user.email)

  user.spree_roles << Spree::Role.find_by(name: 'user')
  address = addresses.pop
  user.bill_address = address
  user.ship_address = address
  user.save
end

# Store Admin user
admin = Spree::User.new(email: Maisonette::Config.fetch('store_defaults.admin_user'), password: SecureRandom.hex(8))
notify_if_saved(admin, admin.email)

admin.spree_roles << Spree::Role.find_by(name: 'admin')
