# frozen_string_literal: true

module Mirakl
  module SubmitCommercialOrder
    class CreateCommercialOrderPayloadInteractor < ApplicationInteractor
      include Mirakl::SubmitCommercialOrder::ExceptionHelper

      def call
        context.commercial_order_payload = create_payload
      rescue StandardError => e
        handle_exception(e)
      end

      private

      def spree_order
        @spree_order ||= context.spree_order
      end

      def create_payload
        general_details.merge(
          customer: customer_details,
          offers: context.offers_details_payload,
          order_additional_fields: order_additional_fields
        ).to_json
      end

      def general_details
        {
          commercial_id: spree_order.number,
          scored: 'true',
          shipping_zone_code: 'USA',
          payment_workflow: 'PAY_ON_ACCEPTANCE',
          payment_info: {
            payment_type: payment_method_type
          }
        }
      end

      def customer_details
        general_customer_details.merge(
          billing_address: address_details(spree_order.bill_address),
          shipping_address: address_details(spree_order.ship_address)
        )
      end

      def general_customer_details
        {
          customer_id: spree_order.email[0...50],
          email: spree_order.email,
          firstname: spree_order.user&.first_name || spree_order.bill_address.firstname,
          lastname: spree_order.user&.last_name || spree_order.bill_address.lastname
        }
      end

      def address_details(address)
        { city: address.city,
          company: address.company || '',
          country: address.country.iso_name,
          country_iso_code: address.country.iso3,
          firstname: address.firstname,
          lastname: address.lastname,
          phone: address.phone,
          phone_secondary: address.alternative_phone || '',
          state: address.state&.name,
          street_1: address.address1,
          street_2: address.address2 || '',
          zip_code: address.zipcode }
      end

      def payment_method_type
        valid_payments = spree_order.payments.valid
        if valid_payments.store_credits.present? && valid_payments.not_store_credits.present?
          return MIRAKL_DATA[:order][:payment_type][:mixed]
        end

        valid_payments.first.payment_method.name
      rescue StandardError
        Sentry.capture_message(I18n.t('errors.mirakl_submit_order_missing_payment_info',
                                      order_number: spree_order.number))
        ''
      end

      def order_additional_fields
        [{ code: MIRAKL_DATA[:order][:additional_fields][:env], value: Rails.env }]
      end
    end
  end
end
