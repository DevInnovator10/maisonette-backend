# frozen_string_literal: true

module Maisonette
  module Kustomer
    class OrderPresenter
      def initialize(order)
        @order = order
      end

      def kustomer_payload # rubocop:disable Metrics/MethodLength
        {
          orderNumber: @order.number,
          email: @order.email,
          shippingAddress: address_info(@order.shipping_address),
          billingAddress: address_info(@order.billing_address),
          lineItemDetails: line_item_details.compact,
          giftDetails: gift_details,
          shipments: shipments_details,
          paymentTotal: @order.total,
          paymentDetails: payments,
          returnAuthorizations: return_authorizations,
          returnItems: return_items,
          reimbursements: reimbursements,
          refunds: refunds,
          credits: credits
        }
      end

      private

      def address_info(address)
        return nil if address.nil? && @order.legacy_order?

        {
          address: address.address1,
          city: address.city,
          zipcode: address.zipcode,
          state: address.state&.name,
          country: address.country.name
        }
      end

      def shipments_details
        @order.shipments.map do |shipment|
          {
            shipmentNumber: shipment.number,
            tracking: shipment.tracking,
            shipmentState: shipment.state,
            eta: shipment.delivery_estimation,
            shippingMethod: shipment.shipping_method&.admin_name,
            stockLocationName: shipment.stock_location.name,
            carrier_code: shipment.shipping_carrier_code,
            trackingUrl: shipment.tracking_url
          }
        end
      end

      def line_item_details # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        @order.line_items.map do |line_item|
          next if line_item.inventory_units.blank?

          line_item_details = {
            shipmentNumber: line_item.inventory_units.first.shipment.number,
            sku: nil,
            maisonetteSku: nil,
            vendorSku: nil,
            quantityOrdered: line_item.quantity,
            quantityShipped: line_item.inventory_units.shipped.count,
            quantityCanceled: line_item.inventory_units.canceled.count,
            quantityReturned: line_item.inventory_units.returned.count,
            images: [],
            monogram: line_item.monogram&.customization&.to_s
          }

          line_item_details.merge!(variant_details(line_item))

          line_item_details
        end
      end

      def variant_details(line_item)
        return {} if line_item.variant.nil?

        offer_settings = find_offer_settings(line_item)

        {
          sku: line_item.sku,
          maisonetteSku: offer_settings.maisonette_sku,
          vendorSku: offer_settings.vendor_sku,
          images: offer_settings.variant.product.images.map { |i| i.attachment.url }.join(',')
        }
      end

      def find_offer_settings(line_item)
        line_item.offer_settings ||
          Spree::OfferSettings.with_discarded.find_by!(vendor_id: line_item.vendor_id,
                                                       maisonette_sku: line_item.variant.sku)
      end

      def gift_details
        {
          giftMessage: @order.gift_message,
          recipientEmail: @order.gift_email,
          wrapped: @order.giftwrapped?
        }
      end

      def payments
        @order.payments.valid.map do |payment|
          {
            name: payment_method_name(payment),
            state: payment.state,
            source_type: payment.source_type,
            amount: payment.amount
          }
        end
      end

      def payment_method_name(payment)
        return payment.payment_method.name unless payment.source.is_a? SolidusPaypalBraintree::Source

        "Braintree::#{payment.source.payment_type}"
      end

      def return_authorizations
        @order.return_authorizations.map do |return_authorization|
          Maisonette::Kustomer::ReturnAuthorizationPresenter.new(return_authorization).kustomer_payload
        end
      end

      def reimbursements
        @order.reimbursements.map do |reimbursement|
          Maisonette::Kustomer::ReimbursementPresenter.new(reimbursement).kustomer_payload
        end
      end

      def return_items
        @order.return_authorizations.map(&:return_items).flatten.map do |return_item|
          Maisonette::Kustomer::ReturnItemPresenter.new(return_item).kustomer_payload
        end
      end

      def refunds
        @order.reimbursements.map(&:refunds).flatten.map do |refund|
          Maisonette::Kustomer::RefundPresenter.new(refund).kustomer_payload
        end
      end

      def credits
        gift_card_reimbursements + store_credits_reimbursements
      end

      def gift_card_reimbursements
        @order.reimbursements.map(&:gift_card_reimbursements).flatten.map do |reimbursement_gift_card|
          Maisonette::Kustomer::Reimbursement::GiftCardPresenter.new(reimbursement_gift_card).kustomer_payload

        end
      end

      def store_credits_reimbursements
        @order.reimbursements.map(&:credits).flatten.map do |credit|
          Maisonette::Kustomer::Reimbursement::CreditPresenter.new(credit).kustomer_payload
        end
      end
    end
  end
end
