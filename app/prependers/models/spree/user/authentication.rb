# frozen_string_literal: true

module Spree::User::Authentication
  def self.prepended(base)
    base.extend ClassMethod
  end

  module ClassMethod
    def authenticate(email, password)
      user = Spree::User.find_for_authentication(email: email)
      user&.valid_password?(password) ? user : nil
    end
  end

  protected

  def extract_ip_from(request)
    request.headers['X-Forwarded-For'] || request.remote_ip
  end
end
