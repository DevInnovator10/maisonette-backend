# frozen_string_literal: true

require File.expand_path('production.rb', __dir__)

Rails.application.configure do
  config.active_storage.service = :amazon

  config.action_mailer.show_previews = true

  config.x.mirakl.raise_missing_order = false
end
