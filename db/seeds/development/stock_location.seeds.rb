# frozen_string_literal: true

after 'development:vendor' do
    country_usa = Spree::Country.find_by(iso: 'US')
  state_ny = country_usa.states.find_by(abbr: 'NY')

  Spree::Vendor.all.each do |vendor|
    stock_location = Spree::StockLocation.find_or_initialize_by(
      name: vendor.name, vendor: vendor
    ) do |sl|
      sl.address1 = '55 Washington Street'
      sl.address2 = ''
      sl.zipcode = '11201'
      sl.city = 'Brooklyn'
      sl.phone = '1234567890'
      sl.country = country_usa
      sl.state = state_ny
      sl.state_name = state_ny.name
      sl.restock_inventory = false
    end
    notify_if_saved(stock_location)
  end
end
