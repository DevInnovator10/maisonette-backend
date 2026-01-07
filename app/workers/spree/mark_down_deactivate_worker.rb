# frozen_string_literal: true

module Spree
  class MarkDownDeactivateWorker
    include Sidekiq::Worker

    sidekiq_options lock: :while_executing, retry: false

    def perform
      Spree::MarkDown.to_deactivate.find_each do |mark_down|
        deactivate! mark_down
      end
    end

    private

    def deactivate!(mark_down)
      mark_down.update!(active: false)
      Spree::MarkDownDeactivateMailer.notify_deactivate(mark_down).deliver_now
    rescue StandardError => e
      error_message = "Verify deactivation of mark down '#{mark_down.title}' with id #{mark_down.id}"
      Sentry.capture_exception_with_message(e, message: error_message)
    end
  end
end
