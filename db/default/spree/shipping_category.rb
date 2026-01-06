# frozen_string_literal: true

I18n.t('seeds.shipping_categories.names').each do |name|
  category = Spree::ShippingCategory.find_or_initialize_by(name: name)
  notify_if_saved(category, name)
end
