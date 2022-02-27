# frozen_string_literal: true

namespace :braintree do
  desc 'Fetch braintree source tokens from braintree'
  task fetch_tokens: :environment do
    if braintree_sources.ids.empty?
      puts 'no sources to process'
      next
    else
      redis.del(redis_key)
      redis.rpush(redis_key, braintree_sources.ids)

      Braintree::FetchCreditCardTokenWorker.perform_async(redis.lpop(redis_key), redis_key)
    end
  end
end

def braintree_sources
  SolidusPaypalBraintree::Source.joins(:payments)
                                .where(spree_payments: { state: 'completed' })
                                .where(token: nil, reusable: true)
                                .where.not(customer_id: nil)
                                .order(created_at: :desc)
end

def redis
  @redis ||= Redis.new(url: redis_url)
end

def redis_url
  "#{Maisonette::Config.fetch('redis.service_url')}/#{Maisonette::Config.fetch('redis.db')}"
end

def redis_key
  'braintree_source:ids'
end
