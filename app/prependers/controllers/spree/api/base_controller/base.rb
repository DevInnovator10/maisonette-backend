# frozen_string_literal: true

module Spree::Api::BaseController::Base
  def self.prepended(base)
    base.prepend_before_action :reject_non_json_requests
  end

  def reject_non_json_requests
    return if request.format.json? || request.format.to_sym.nil?

    render json: { error: 'This application only accepts JSON requests.' }, status: :not_acceptable
  end

  def not_found
    render 'spree/api/errors/not_found', status: :not_found
  end

  def append_info_to_payload(payload)
    super

    payload[:level] = case payload[:status].to_s[0]
                      when '2'
                        'INFO'
                      when '4'
                        'WARN'
                      when '3'
                        'WARN'
                      else
                        'ERROR'
                      end
  end
end
