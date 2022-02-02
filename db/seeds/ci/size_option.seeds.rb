# frozen_string_literal: true

option_type = Spree::OptionType.find_or_initialize_by(name: 'Size', presentation: 'Size')
notify_if_saved(option_type, 'OptionType - Size')

I18n.t('seeds.size_options.names').each do |name|
  Spree::OptionValue.create(
    name: name,
    presentation: name,
    option_type: option_type
  )
end
