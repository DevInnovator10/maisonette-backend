# frozen_string_literal: true

module Maisonette
  module Kustomer
    class Customer < Maisonette::Kustomer::Entity
      def self.advisory_lock(target_object)
        Maisonette::Kustomer::Entity.with_advisory_lock(advisory_lock_key(target_object), timeout_seconds: 10) do
          yield
        end
      end

      def self.advisory_lock_key(target_object)
        Maisonette::Kustomer::Entity.advisory_lock_key(name, target_object)
      end

      def self.webhook_path
        Maisonette::Config.fetch('kustomer.webhooks.customer')
      end

      private

      def payload_presenter_class
        Maisonette::Kustomer::CustomerPresenter
      end
    end
  end
end
