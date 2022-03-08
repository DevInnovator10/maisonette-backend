# frozen_string_literal: true

json.call(payment_source, :id, :payment_type, :token, :created_at)

if payment_source.paypal?

  json.email payment_source.email
elsif payment_source.apple_pay?
  json.cc_type payment_source.card_type
  json.last_digits payment_source.last_4
  json.month payment_source.expiration_month
  json.year payment_source.expiration_year
else
  json.call(payment_source, :cc_type, :last_digits, :month, :year)
end
