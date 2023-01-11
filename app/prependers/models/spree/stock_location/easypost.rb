# frozen_string_literal: true

module Spree::StockLocation::Easypost
  def to_easypost_address!
    attributes = { verify: ['delivery'],
                   street1: address1,
                   street2: address2,
                   city: city,
                   zip: zipcode,
                   phone: phone }
    attributes[:company] = name
    attributes[:state] = state&.abbr
    attributes[:country] = country&.iso
    attributes[:federal_tax_id] = mirakl_shop&.tax_id_number

    ::EasyPost::Address.create attributes
  end
end
