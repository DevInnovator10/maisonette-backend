class FlipperCheckoutAddressVerification < ActiveRecord::Migration[6.0]
  def up
    Flipper[:checkout_address_verification].disable unless Flipper[:checkout_address_verification].exist?
  end

  def down
    Flipper[:checkout_address_verification].remove
  end
end
