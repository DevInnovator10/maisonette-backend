# frozen_string_literal: true

require File.expand_path('production.rb', __dir__)

Rails.application.configure do
    config.x.mirakl.raise_missing_order = false

  config.x.sentry.traces_sample_rate = 1.0
end
