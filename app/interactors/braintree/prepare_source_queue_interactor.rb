# frozen_string_literal: true

module Braintree
  class PrepareSourceQueueInteractor < ApplicationInteractor
    def call
      redis.del(redis_key)
      return if braintree_sources.ids.empty?

      redis.rpush(redis_key, braintree_sources.ids)

      Braintree::FillCustomerInfoWorker.perform_async
    end

    private

    def braintree_sources
      SolidusPaypalBraintree::Source.joins(:customer)
                                    .where.not(solidus_paypal_braintree_customers: { braintree_customer_id: nil })
                                    .where(solidus_paypal_braintree_customers: { filled: false })
                                    .order(created_at: :asc)
    end

    def redis
      @redis ||= Redis.new(url: redis_url)
    end

    def redis_url
      "#{Maisonette::Config.fetch('redis.service_url')}/#{Maisonette::Config.fetch('redis.db')}"
    end

    def redis_key
      Braintree::FillCustomerInfoWorker::BRAINTREE_CUSTOMER_QUEUE_KEY
    end
  end
end
