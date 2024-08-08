# frozen_string_literal: true

module OrderManagement
  class OrderDeliveryMethodPresenter
    def initialize(shipping_method)
      @shipping_method = shipping_method
    end

    def payload
      { 'Name': @shipping_method.name }
    end
  end
end
