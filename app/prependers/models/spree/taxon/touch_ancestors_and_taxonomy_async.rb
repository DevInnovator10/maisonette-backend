# frozen_string_literal: true

module Spree::Taxon::TouchAncestorsAndTaxonomyAsync
  def touch_ancestors_and_taxonomy
    return if ancestors.blank?

    redis.sadd(Maisonette::Config.fetch('redis.taxon_ids_touch_list'), ancestors.pluck(:id))
  end

  def redis
    @redis ||= Redis.new(url: redis_url)
  end

  def redis_url
    "#{Maisonette::Config.fetch('redis.service_url')}/#{Maisonette::Config.fetch('redis.db')}"
  end
end
