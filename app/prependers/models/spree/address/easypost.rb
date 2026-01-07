# frozen_string_literal: true

module Spree::Address::Easypost
    def to_easypost_address!(verify: true) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    attributes = { street1: address1,
                   street2: address2,
                   city: city,
                   zip: zipcode,
                   phone: phone }
    attributes[:company] = company
    attributes[:name] = full_name unless warehouse
    attributes[:state] = state&.abbr
    attributes[:country] = country&.iso
    attributes[:federal_tax_id] = warehouse&.mirakl_shop&.tax_id_number if warehouse

    if verify
      attributes[:verify] = country&.iso == 'US' ? ['zip4'] : ['delivery']
    else
      attributes[:residential] = residential
    end

    ::EasyPost::Address.create attributes
  end

  def self.prepended(base)
    base.singleton_class.prepend ClassMethods
  end

  module ClassMethods
    def value_attributes(base_attributes, merge_attributes = {})
      super.except('easypost_address_id', 'name')
    end

    def factory(attributes)
      super(attributes.except(:name)).tap do |address|
        address.easypost_address_id ||= attributes['easypost_address_id']
      end
    end
  end
end
