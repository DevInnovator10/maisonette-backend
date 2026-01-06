# frozen_string_literal: true

module Spree::Address::PhoneValidation
  def valid_phone_number?
    phone.count('0123456789') > 9
  end
end
