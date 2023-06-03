# frozen_string_literal: true

module Klaviyo
  class Client < Api
    include Klaviyo::Basic::Identify
    include Klaviyo::Basic::Track

    attr_reader :private_api_key, :public_api_key

    def initialize(public_key: nil, private_key: nil)
      @private_api_key = private_key || default_private_key
      @public_api_key = public_key || default_public_key
    end

    def list(list_id = nil)
      Klaviyo::Client::Lists.new(client: self, list_id: list_id)
    end
    alias :lists :list

    def data_privacy
      Klaviyo::Client::DataPrivacy.new(client: self)
    end
  end
end
