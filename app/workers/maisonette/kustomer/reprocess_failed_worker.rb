# frozen_string_literal: true

module Maisonette
  module Kustomer
    class ReprocessFailedWorker
      include Sidekiq::Worker

      const_set 'REDIS_QUEUE_KEY', 'kustomer_entity:ids'

      sidekiq_options retry: false

      def perform
        return if source_id.nil?

        Maisonette::Kustomer::SyncWorker.perform_async(source_id)

        self.class.perform_in(worker_latency.to_d.seconds)
      end

      private

      def redis_key
        Maisonette::Kustomer::ReprocessFailedWorker::REDIS_QUEUE_KEY
      end

      def source_id
        @source_id ||= redis.lpop(redis_key)
      end

      def redis
        @redis ||= Redis.new(url: redis_url)
      end

      def redis_url
        "#{Maisonette::Config.fetch('redis.service_url')}/#{Maisonette::Config.fetch('redis.db')}"
      end

      def worker_latency
        redis.get('reprocess_failed_worker:seconds') || 0.25 # Kustomer Rate is 1000/minute
      end
    end
  end
end
