# frozen_string_literal: true

module Klaviyo
  class ListSubscriberInteractor < ApplicationInteractor
    helper_methods :subscriber, :email, :status, :list_id, :source, :other_payload_data

    before :verify_subscriber!, :extract_klaviyo_attrs, :verify_klaviyo_data!

    def call
      client = Klaviyo::Client.new
      client.list(list_id).public_send(klaviyo_action, payload)
    rescue RestClient::BadRequest => e
      handle_bad_request(e)
    end

    private

    def verify_subscriber!
      context.fail!(message: 'subscriber required') unless subscriber.is_a? Maisonette::Subscriber
    end

    def extract_klaviyo_attrs
      context.email = subscriber.email
      context.status = subscriber.status
      context.list_id = subscriber.list_id
      context.source = subscriber.source

      context.other_payload_data = subscriber.slice(*additional_klaviyo_attributes)
    end

    def verify_klaviyo_data!
      context.fail!(message: 'list_id required') unless list_id
      context.fail!(message: 'status required') unless klaviyo_action
    end

    def payload
      if klaviyo_action == :subscribe
        { email: email, subscribed_from: source }.merge(other_payload_data).symbolize_keys
      else
        { emails: [email] }
      end
    end

    def klaviyo_action
      @klaviyo_action ||= { 'subscribed' => :subscribe, 'unsubscribed' => :unsubscribe }.dig(status)
    end

    def additional_klaviyo_attributes
      [:phone]
    end

    def handle_bad_request(exception)
      if klaviyo_action == :subscribe && exception.response.to_s.include?('is not a valid email')
        subscriber.destroy
        context.invalid_email_address = true
      end
      context.fail!(message: "Klaviyo request error: #{exception} - #{exception.response}")
    end
  end
end
