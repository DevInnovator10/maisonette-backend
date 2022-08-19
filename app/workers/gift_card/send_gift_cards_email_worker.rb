# frozen_string_literal: true

module GiftCard
  class SendGiftCardsEmailWorker
    include Sidekiq::Worker

    def perform(*_args)
      Spree::GiftCard.where('send_email_at <= ?', Time.zone.today.end_of_day).where(sent_at: nil, redeemable: true)
                     .find_each(&:send_email)
    rescue StandardError => e
      Sentry.capture_exception_with_message(e)
    end
  end
end
