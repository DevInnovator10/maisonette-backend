# frozen_string_literal: true

module Sessions
  class TrimWorker

    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(*_args)
      rake = Rake.application
      rake.load_rakefile
      rake['db:sessions:trim'].invoke
    end
  end
end
