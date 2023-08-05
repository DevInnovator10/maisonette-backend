# frozen_string_literal: true

module Maisonette
  class SitemapWorker

    include Sidekiq::Worker

    def perform(*_args)
      SitemapGenerator::Interpreter.run
    end
  end
end
