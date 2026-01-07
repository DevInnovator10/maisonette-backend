# frozen_string_literal: true

module Spree::Address::DisplayAddress
  def display_address
    [
      "#{firstname} #{lastname}",
      company,
      "#{address1}, #{address2}",
      "#{city}, #{state ? state.abbr : state_name} #{zipcode}",
      country.to_s,
      phone
    ].compact.join('<br/>')
  end
end
