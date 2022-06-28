# frozen_string_literal: true

module OrderManagement
  class OrderDeliveryMethod < OrderManagement::Entity
    def self.order_management_object_name
      'OrderDeliveryMethod'
    end

    def self.payload_presenter_class
      OrderManagement::OrderDeliveryMethodPresenter
    end
  end
end
