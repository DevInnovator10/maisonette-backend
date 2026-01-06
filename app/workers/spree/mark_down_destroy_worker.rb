# frozen_string_literal: true

module Spree
  class MarkDownDestroyWorker
    include Sidekiq::Worker

    sidekiq_options lock: :while_executing, retry: false

    def perform(mark_down_id)
      @mark_down_id = mark_down_id
      mark_down.destroy!

      send_destroyed_email
    rescue StandardError => e
      Sentry.capture_exception_with_message(e, message: "Mark Down: #{mark_down.title}")
      send_destroyed_error_email
    end

    private

    def mark_down
      @mark_down ||= Spree::MarkDown.find(@mark_down_id)
    end

    def send_destroyed_email
      Spree::MarkDownUpdatePricesMailer.send_destroyed_email(mark_down.title).deliver_later
    end

    def send_destroyed_error_email
      Spree::MarkDownUpdatePricesMailer.send_destroyed_error_email(mark_down.title).deliver_later
    end
  end
end
