# frozen_string_literal: true

namespace :factory_bot do
  desc 'Verify that all FactoryBot factories are valid'
  task lint: :environment do

    if Rails.env.test?
      require 'spree/testing_support/factories'
      DatabaseCleaner.cleaning do
        FactoryBot.lint
      end
    else
      system("bundle exec rake factory_bot:lint RAILS_ENV='test'")
      raise if $CHILD_STATUS.exitstatus.nonzero?
    end
  end
end
