# frozen_string_literal: true

module Mirakl
  class UpdateOffersJsonInteractor < ApplicationInteractor
    include Mirakl::Api

    required_params :offers_payload, :shop_id

    helper_methods :offers_payload, :shop_id

    before :use_operator_key

    def call
      post("/offers?shop=#{shop_id}", payload: payload)
    rescue StandardError => e
      rescue_and_capture(e, error_details: "#{shop_id}\n\n#{offers_payload}")
    end

    private

    def payload
      { offers: offers_payload }.to_json
    end
  end
end
