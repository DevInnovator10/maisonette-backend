# frozen_string_literal: true

country_attrs = {
  name: I18n.t('seeds.addresses.countries.us'),
  iso_name: I18n.t('seeds.addresses.countries.us').upcase
}

country = Spree::Country.find_or_initialize_by(country_attrs)
notify_if_saved(country)

if country.states.empty?
  I18n.t('seeds.addresses.states').each_pair do |abbr, name|
    state = country.states.new(name: name, abbr: abbr)

    notify_if_saved(state)
  end
end

20.times do
  address = Spree::Address.new(
    firstname: FFaker::Name.first_name,
    lastname: FFaker::Name.last_name,
    address1: '55 Washington Street',
    address2: '',
    city: 'Brooklyn',
    zipcode: '11201',
    phone: '1234567890',
    state: country.states.find_by(abbr: 'NY'),
    country: country
  )
  notify_if_saved(address)
end
