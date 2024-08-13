# frozen_string_literal: true

module Forter
  class OrderPresenter
    include Payments::CreditCard
    include Payments::GiftCard
    include Payments::Paypal
    include Payments::StoreCredit

    def initialize(order, historical: false, failed_payment_id: nil)
      @order = order
      @historical = historical
      @failed_payment_id = failed_payment_id
      @current_time = Time.current
    end

    def validation_payload
      change_nil_to_s([validation_base_attributes,
                       connection_information,
                       amount,
                       discount,
                       account_owner,
                       items,
                       payments,
                       delivery_details,
                       beneficiary,
                       historical_data].reduce(&:merge))
    end

    def order_status_payload
      change_nil_to_s([order_status_base_attributes,
                       amount(tag: :updatedTotalAmount),
                       payments].reduce(&:merge))
    end

    private

    def change_nil_to_s(hash)
      hash.deep_transform_values do |value|
        value.nil? ? '' : value
      end
    end

    def validation_base_attributes
      {
        orderId: @order.number,
        orderType: 'WEB',
        authorizationStep: 'PRE_AUTHORIZATION',
        timeSentToForter: @current_time.to_datetime.strftime('%Q').to_i,
        checkoutTime: (@order.completed_at || @current_time).to_i
      }
    end

    def order_status_base_attributes
      {
        orderId: @order.number,
        eventTime: @current_time.to_datetime.strftime('%Q').to_i,
        updatedStatus: order_status
      }
    end

    def additional_order_identifies; end

    def connection_information
      connection_info = @order.forter_connection_info
      { connectionInformation: { customerIP: @order.last_ip_address,
                                 userAgent: connection_info['user_agent'],
                                 forterTokenCookie: connection_info['token'],
                                 forterMobileUID: connection_info['mobile_uid'] } }
    end

    def amount(tag: :totalAmount)
      { tag.to_sym => { amountUSD: @order.total.to_s,
                        currency: @order.currency } }
    end

    def discount
      coupon_adjustment = @order.all_adjustments.eligible.promotion.detect { |adj| adj.promotion_code&.value }
      return {} unless coupon_adjustment

      { totalDiscount: { couponCodeUsed: coupon_adjustment.promotion_code&.value,
                         discountType: 'COUPON' } }
    end

    def account_owner # rubocop:disable Metrics/AbcSize
      user = @order.user
      guest = @order.bill_address
      maisonette_customer = user&.maisonette_customer

      past_orders = maisonette_customer&.orders&.complete || Spree::Order.complete.where(email: @order.email)
      { accountOwner: { firstName: user&.first_name || guest.firstname,
                        lastName: user&.last_name || guest.lastname,
                        email: user&.email || @order.email,
                        accountId: (maisonette_customer&.id || user&.id).to_s,
                        created: (user&.created_at || maisonette_customer&.created_at).to_i,
                        pastOrdersCount: past_orders&.size.to_i,
                        pastOrdersSum: past_orders_sum(past_orders) } }
    end

    def past_orders_sum(past_orders)
      past_orders&.sum { |past_order| past_order.payments.completed.sum(:amount) }.to_f
    end

    def items
      line_items = @order.line_items
      line_items_payload = line_items.map do |line_item|
        { basicItemData: { productId: line_item.sku,
                           name: line_item.name,
                           quantity: line_item.quantity,
                           category: line_item.product.type&.name,
                           type: line_item.variant&.shipping_category&.name == 'Digital' ? 'NON_TANGIBLE' : 'TANGIBLE',
                           price: { amountUSD: line_item.discounted_amount.to_s,
                                    currency: line_item.currency } } }
      end
      { cartItems: line_items_payload }
    end

    def payments
      order_payments = [Spree::Payment.find(@failed_payment_id)] if @failed_payment_id
      order_payments ||= @order.completed? ? @order.payments.completed : @order.payments.checkout
      billing_details = { billingDetails: personal_details(@order.bill_address) }

      payments_payload = order_payments.map do |payment|
        payment_payload(billing_details, payment)
      end || {}
      if (gift_card_adjustment = @order.gift_card_adjustments.first)
        payments_payload << gift_card(gift_card_adjustment).merge(billing_details)
      end
      { payment: payments_payload }
    end

    def payment_payload(billing_details, payment) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      payment_payload = if payment.store_credit?
                          store_credit(payment)
                        elsif payment.payment_source.try(:credit_card?)
                          credit_card(payment, tag: :creditCard)
                        elsif payment.payment_source.try(:paypal?)
                          paypal(payment)
                        elsif payment.payment_source.try(:apple_pay?)
                          credit_card(payment, tag: :applePay)
                        else
                          {}
                        end

      payment_payload.merge!(billing_details)
      payment_payload.merge!(
        amount: {
          amountUSD: payment.amount.to_s,
          currency: payment.currency
        },
        savedData: { usedSavedData: used_saved_data?(payment),
                     choseToSaveData: true }, # we always save
        updateTimes: { creationTime: payment.payment_source.created_at.to_i,
                       lastModifiedTime: payment.payment_source.updated_at.to_i }
      )
      payment_last_used = payment.payment_source.payments.completed.where.not(id: payment.id).last
      payment_payload[:updateTimes][:lastUsed] = payment_last_used.updated_at.to_i if payment_last_used
      payment_payload
    end

    def used_saved_data?(payment)
      return false unless @order.user

      payment.payment_source.try(:token)&.in?(
        @order.user.wallet_payment_sources.map { |wps| wps.payment_source.token }
      ) || false
    end

    def delivery_details
      shipping_methods = @order.shipments.map { |shipment| shipment.selected_shipping_rate.shipping_method }.uniq
      { primaryDeliveryDetails: { deliveryType: delivery_type(shipping_methods),
                                  deliveryMethod: shipping_methods.size == 1 ? shipping_methods[0].admin_name : 'Mixed',
                                  deliveryPrice: { amountUSD: @order.shipment_total.to_s,
                                                   currency: @order.currency } } }
    end

    def delivery_type(shipping_methods)
      shipping_method_admin_names = shipping_methods.map(&:admin_name).uniq
      digital_shipments_count =
        shipping_method_admin_names.count { |admin_name| admin_name == MIRAKL_DATA[:free_shipping_gift_cards] }
      if shipping_method_admin_names.count == digital_shipments_count
        'DIGITAL'
      elsif digital_shipments_count.positive?
        'HYBRID'
      else
        'PHYSICAL'
      end
    end

    def beneficiary
      { primaryRecipient: personal_details(@order.ship_address) }
    end

    def personal_details(address)
      { personalDetails: { firstName: address.firstname,
                           lastName: address.lastname },
        address: { address1: address.address1,
                   address2: address.address2,
                   zip: address.zipcode,
                   city: address.city,
                   region: address.state&.name || address.state_name,
                   country: address.country&.iso,
                   company: address.company },
        phone: [{ phone: address.phone&.scan(/\+?[0-9]+/)&.join }] }
    end

    def historical_data
      return {} unless @historical

      { historicalData: { orderStatus: order_status,
                          fraud: ('FRAUD_REFUND' if refund_reasons.include?('Fraud Cancellation')) } }
    end

    def order_status # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
      return 'CANCELED_BY_MERCHANT' unless @order.completed?

      inventory_unit_statuses = @order.inventory_units.pluck(:state)
      return 'PROCESSING' if inventory_unit_statuses.empty?

      if inventory_unit_statuses.all? { |inventory_unit_status| inventory_unit_status == 'canceled' }
        if (refund_reasons & ['Client Requested Cancellation',
                              'Customer Cancellation',
                              'Cancelled by the client prior to Acceptance']).any?
          'CANCELED_BY_CUSTOMER'
        else
          'CANCELED_BY_MERCHANT'
        end
      elsif inventory_unit_statuses.all? { |inventory_unit_status| inventory_unit_status == 'shipped' }
        'COMPLETED'
      elsif inventory_unit_statuses.any? { |inventory_unit_status| inventory_unit_status == 'shipped' }
        'SENT'
      else
        'PROCESSING'
      end
    end

    def refund_reasons
      @refund_reasons ||=
        Mirakl::OrderLineReimbursement.joins(:order_line)
                                      .where(mirakl_order_lines: { line_item_id: @order.line_item_ids })
                                      .joins(:refund_reason)
                                      .pluck(:name)
                                      .uniq
    end
  end
end
