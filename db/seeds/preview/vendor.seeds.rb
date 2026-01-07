# frozen_string_literal: true

I18n.t('seeds.vendors').each do |vendor_data|
  vendor = Spree::Vendor.find_or_initialize_by(name: vendor_data[:name])
  vendor.assign_attributes(vendor_data[:vendor_attributes]) if vendor_data[:vendor_attributes]
  vendor.avalara_code = vendor_data[:mirakl_attributes][:shop_id]

  notify_if_saved(vendor)
end
