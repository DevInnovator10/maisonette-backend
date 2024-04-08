# frozen_string_literal: true

module Spree::Product::TouchTaxonsAsync
  def touch_taxons
    taxons_to_touch = taxons.map(&:self_and_ancestors).flatten.uniq
    return if taxons_to_touch.blank?

    taxons_ids = taxons_to_touch.pluck(:id)
    redis.sadd(Maisonette::Config.fetch('redis.taxon_ids_touch_list'), taxons_ids)
  rescue StandardError => e
    Sentry.capture_exception_with_message(e, message: "Taxons: #{taxons_ids}")
  end

  private

  def redis
    @redis ||= Redis.new(url: redis_url)
  end

  def redis_url
    "#{Maisonette::Config.fetch('redis.service_url')}/#{Maisonette::Config.fetch('redis.db')}"
  end
end
