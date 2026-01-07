# frozen_string_literal: true

module Narvar
  module Api

    module Commands
      class CreateOrderInteractor < ApplicationInteractor
        include Base

        before :validate_context

        def call
          context.result = post '', payload
        end

        private

        def payload
          payload = Narvar::Api::Payloads::Order.new(context.order).payload.to_json
          Rails.logger.info "Order Payload for narvar #{payload}"
          payload
        end

        def validate_context
          context.fail! error: 'Order required' unless context.order
        end
      end
    end
  end
end
