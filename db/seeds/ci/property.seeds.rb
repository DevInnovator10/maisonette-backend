# frozen_string_literal: true

I18n.t('seeds.properties.names').each do |name|
  property = Spree::Property.find_or_initialize_by(
    name: name, presentation: name
  )
  notify_if_saved(property, name)
end
