# frozen_string_literal: true

I18n.t('seeds.roles.names').each do |name|
  role = Spree::Role.find_or_initialize_by(name: name)
  notify_if_saved(role, name)
end
