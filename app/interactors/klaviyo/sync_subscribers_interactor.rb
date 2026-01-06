# frozen_string_literal: true

module Klaviyo
  class SyncSubscribersInteractor < ApplicationInteractor
    def call
      not_synced_subscribers = Maisonette::Subscriber.not_synced
      return if not_synced_subscribers.empty?

      subscribed_users = not_synced_subscribers.each_slice(100).flat_map(&method(:fetch_subscribers))
      subscribers_to_sync = fetch_subscribers_from_list(not_synced_subscribers, subscribed_users)

      process_synced_subscribed_users(subscribers_to_sync)
      process_unsynced_subscribed_users(subscribers_to_sync)
      process_synced_unsubscribed_users(subscribers_to_sync)
      process_unsynced_unsubscribed_users(subscribers_to_sync)
      process_synced_deleted_users(subscribers_to_sync)
      process_unsynced_deleted_users(subscribers_to_sync)
    end

    private

    def fetch_subscribers(sliced_not_synced_subscribers)
      Klaviyo::Client.new.list(list_id).fetch_subscribers(subscriber_data(sliced_not_synced_subscribers))
    end

    def subscriber_data(not_synced_subscribers)
      not_synced_subscribers.map do |subscriber|
        { email: subscriber.email, phone_number: subscriber.phone }
      end
    end

    def fetch_subscribers_from_list(not_synced_subscribers, subscribed_users)
      subscribed_users.map do |subscribed_user|
        subscriber = not_synced_subscribers.where('email ILIKE ? OR phone = ?',
                                                  subscribed_user['email'],
                                                  subscribed_user['phone']).first
        raise('Could not find subscriber in our records') unless subscriber

        subscriber.update_column('klaviyo_id', subscribed_user['id']) # rubocop:disable Rails/SkipsModelValidations
        subscriber
      rescue StandardError => e
        capture_exception(e, subscribed_user)
        next
      end.compact
    end

    def process_synced_subscribed_users(subscribed_users)
      (Maisonette::Subscriber.subscribed & subscribed_users).each do |subscribed_user|
        subscribed_user.subscribed_and_synced!
      rescue StandardError => e
        capture_exception(e, subscribed_user.attributes)
      end
    end

    def process_unsynced_subscribed_users(subscribed_users)
      (Maisonette::Subscriber.subscribed - subscribed_users).each do |subscribed_user|
        subscribed_user.unsubscribed_and_synced! if subscribed_user.updated_at < (Time.current - response_timeout)
      rescue StandardError => e
        capture_exception(e, subscribed_user.attributes)
      end
    end

    def process_synced_unsubscribed_users(subscribed_users)
      (Maisonette::Subscriber.unsubscribed - subscribed_users).each do |unsubscribed_user|
        unsubscribed_user.unsubscribed_and_synced!
      rescue StandardError => e
        capture_exception(e, unsubscribed_user.attributes)
      end
    end

    def process_unsynced_unsubscribed_users(subscribed_users)
      (Maisonette::Subscriber.unsubscribed & subscribed_users).each do |unsubscribed_user|
        # retry to unsubscribe
        unsubscribed_user.touch # rubocop:disable Rails/SkipsModelValidations
        Sentry.capture_message("#{self.class.name} - User not unsubscribed, retrying\n#{unsubscribed_user.attributes}")
      rescue StandardError => e
        capture_exception(e, unsubscribed_user.attributes)
      end
    end

    def process_synced_deleted_users(subscribed_users)
      (Maisonette::Subscriber.deleted - subscribed_users).each do |deleted_user|
        deleted_user.deleted_and_synced!
      rescue StandardError => e
        capture_exception(e, deleted_user.attributes)
      end
    end

    def process_unsynced_deleted_users(subscribed_users)
      (Maisonette::Subscriber.deleted & subscribed_users).each do |deleted_user|
        # retry to delete
        deleted_user.touch # rubocop:disable Rails/SkipsModelValidations
        Sentry.capture_message("#{self.class.name} - User not deleted, retrying\n#{deleted_user.attributes}")
      rescue StandardError => e
        capture_exception(e, deleted_user.attributes)
      end
    end

    def capture_exception(exception, message)
      Sentry.capture_exception_with_message(exception, message: message.to_s)
    end

    def list_id
      Maisonette::Config.fetch('klaviyo.default_list_id')
    end

    def response_timeout
      14.days
    end
  end
end
