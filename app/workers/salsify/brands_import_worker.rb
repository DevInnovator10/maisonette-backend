# frozen_string_literal: true

module Salsify
  class BrandsImportWorker
    include Sidekiq::Worker

    sidekiq_options lock: :while_executing

    def perform
      Salsify::BrandsImportInteractor.call
    end
  end
end
