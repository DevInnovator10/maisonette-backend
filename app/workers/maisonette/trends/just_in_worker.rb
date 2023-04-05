# frozen_string_literal: true

module Maisonette
  module Trends
    class JustInWorker
      include Sidekiq::Worker

      sidekiq_options lock: :until_and_while_executing, retry: false

      def perform(*_args)
        Maisonette::Trends::JustInOrganizer.call!
      end
    end
  end
end
