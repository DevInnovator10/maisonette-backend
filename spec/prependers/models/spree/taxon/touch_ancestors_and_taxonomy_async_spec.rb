# frozen_string_literal: true

require 'rails_helper'
require 'mock_redis'

RSpec.describe Spree::Taxon::TouchAncestorsAndTaxonomyAsync, :mock_redis, type: :model do
  let(:taxon) { create(:taxon, parent_id: parent.id) }
  let(:parent) { create(:taxon) }
  let(:redis) do
    Redis.new(url: "#{Maisonette::Config.fetch('redis.service_url')}/#{Maisonette::Config.fetch('redis.db')}")
  end
  let(:taxon_list) { Maisonette::Config.fetch('redis.taxon_ids_touch_list') }

  describe '#touch' do
    it 'queues to redis list' do
      expect { taxon.touch }.to change { redis.smembers(taxon_list) }.from([]).to [parent.id.to_s]
    end
  end
end
