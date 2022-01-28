# frozen_string_literal: true

module Mirakl
  class Order < Mirakl::Base
    module StateMachine
      STATES = %w[WAITING_ACCEPTANCE

                  WAITING_DEBIT_PAYMENT
                  REFUSED
                  CANCELED
                  SHIPPING
                  SHIPPED
                  RECEIVED
                  CLOSED].freeze

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/BlockLength
      def self.included(klass)
        klass.class_eval do
          state_machine initial: :WAITING_ACCEPTANCE, use_transactions: false do
            event :waiting_debit_payment do
              transition to: :WAITING_DEBIT_PAYMENT
            end

            event :refused do
              transition to: :REFUSED
            end

            event :canceled do
              transition to: :CANCELED
            end

            event :shipping do
              transition to: :SHIPPING
            end

            event :shipped do
              transition to: :SHIPPED
            end

            event :received do
              transition to: :RECEIVED
            end

            event :closed do
              transition to: :CLOSED
            end

            before_transition to: :WAITING_DEBIT_PAYMENT do |mirakl_order|
              mirakl_order.acceptance_decision_date ||= mirakl_order.mirakl_payload['acceptance_decision_date']
            end

            after_transition to: :WAITING_DEBIT_PAYMENT do |mirakl_order|
              @context = Mirakl::OrderStateMachine::WaitingDebitPaymentOrganizer.call(mirakl_order: mirakl_order)
            end

            after_transition to: :SHIPPING do |mirakl_order, transition|
              @context = Mirakl::OrderStateMachine::ShippingOrganizer.call(mirakl_order: mirakl_order)
              Spree::Event.fire('mirakl_order_state_changed', state: transition.to, mirakl_order: mirakl_order)
            end

            before_transition to: :SHIPPED do |mirakl_order|
              mirakl_order.invoicing_date ||= mirakl_order.shipped_date
            end

            after_transition to: :SHIPPED do |mirakl_order, transition|
              @context = Mirakl::OrderStateMachine::ShippedOrganizer.call(mirakl_order: mirakl_order)
              Spree::Event.fire('mirakl_order_state_changed', state: transition.to, mirakl_order: mirakl_order)
            end

            before_transition to: :REFUSED do |mirakl_order|
              mirakl_order.invoicing_date ||= mirakl_order.mirakl_payload['acceptance_decision_date']
            end

            after_transition to: :REFUSED do |mirakl_order|
              @context = Mirakl::OrderStateMachine::RefusedOrganizer.call(mirakl_order: mirakl_order)
            end

            before_transition to: :CANCELED do |mirakl_order|
              mirakl_order.invoicing_date ||= mirakl_order.mirakl_payload['last_updated_date']
            end

            after_transition to: :CANCELED do |mirakl_order|
              @context = Mirakl::OrderStateMachine::CanceledOrganizer.call(mirakl_order: mirakl_order)
            end

            before_transition to: :CLOSED do |mirakl_order|
              mirakl_order.invoicing_date ||= mirakl_order.mirakl_payload['last_updated_date']
            end

            after_transition to: :CLOSED do |mirakl_order|
              @context = Mirakl::OrderStateMachine::ClosedOrganizer.call(mirakl_order: mirakl_order)
            end

            before_transition to: :RECEIVED do |mirakl_order|
              mirakl_order.invoicing_date ||= mirakl_order.mirakl_payload['order_lines'].detect do |ol|
                ol['received_date']
              end&.fetch('received_date')
            end

            after_transition to: :RECEIVED do |mirakl_order|
              @context = Mirakl::OrderStateMachine::ReceivedOrganizer.call(mirakl_order: mirakl_order)
            end

            after_transition do |mirakl_order, _transition|
              mirakl_order.log_entries.create!(details: @context.to_yaml)
            rescue StandardError => e
              Sentry.capture_exception_with_message(e, message: 'failed to create event log entry')
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/BlockLength
    end
  end
end
