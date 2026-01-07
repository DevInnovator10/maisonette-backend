# frozen_string_literal: true

module SolidusAvataxCertified::Request::Base::CustomerCode
    private

  def customer_code
    order.maisonette_customer_id || order.number
  end
end
