# frozen_string_literal: true

module OrderManagement
  class DeliveryGroupPresenter
    def initialize(order, is_historical_order = false)
      @order = order
      @is_historical_order = is_historical_order
      @shipping_methods = @order.shipments.map(&:shipping_method)
      @flat_rate_shipping_method = @shipping_methods
                                   .reject { |sm| sm.base_flat_rate_amount.zero? }
                                   .max_by(&:base_flat_rate_amount)
      @delivery_groups = @shipping_methods
                         .select { |sm| sm.base_flat_rate_amount.zero? || sm.expedited }
    end

    def flat_rate_payload
      return if @flat_rate_shipping_method.nil?

      base_payload.tap do |payload|
        payload[:OrderDeliveryMethodId] = order_delivery_method_id(@flat_rate_shipping_method)
        payload[:DeliveryGroupIdentifier] = "#{@order.number}-flat" if @is_historical_order
      end
    end

    def delivery_groups_payload
      @delivery_groups.map do |delivery_group|
        base_payload.tap do |payload|
          payload[:attributes] = { type: 'OrderDeliveryGroup' }
          payload[:OrderDeliveryMethodId] = order_delivery_method_id(delivery_group)
          payload[:DeliveryGroupIdentifier] = "#{@order.number}-#{delivery_group.id}" if @is_historical_order
          payload[:Parent_Delivery_Group_ID__c] = '@{refFlatRateDeliveryGroup.id}' if delivery_group.expedited
        end
      end
    end

    def get_reference(shipping_method)
      if !shipping_method.expedited && !shipping_method.base_flat_rate_amount.zero?
        'refFlatRateDeliveryGroup'
      else
        "refDeliveryGroups[#{@delivery_groups.find_index(shipping_method)}]"
      end
    end

    private

    def base_payload
      shipping_address = @order.shipping_address

      {
        EmailAddress: @order.email,
        DeliverToCity: shipping_address.city,
        DeliverToCountry: shipping_address.country.iso,
        DeliverToName: shipping_address.full_name,
        DeliverToPostalCode: shipping_address.zipcode,
        DeliverToState: shipping_address.state&.abbr,
        DeliverToStreet: shipping_address.address1,
        PhoneNumber: shipping_address.phone,
        OrderId: '@{refOrder.id}'
      }
    end

    def order_delivery_method_id(shipping_method)
      OrderManagement::OrderDeliveryMethod.find_by!(
        order_manageable: shipping_method
      ).order_management_entity_ref
    end
  end
end
