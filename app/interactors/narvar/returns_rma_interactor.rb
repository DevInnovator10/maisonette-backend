# frozen_string_literal: true

module Narvar
  class ReturnsRmaInteractor < ApplicationInteractor
    before :validate_context
    before :prepare_context
    after :check_errors

    def call
      process_items(prepare_items(context.request['items']))
    end

    private

    def add_unit(unit, item)
      @default_reason ||= Spree::ReturnReason.find_by name: 'Other'
      unit[:reason] =
        Spree::ReturnReason.find_by(mirakl_code: item['reason_code']) ||
        Spree::ReturnReason.find_by(name: item['reason']) ||
        @default_reason
      unit[:comment] = "#{item['sku']}: #{item['comment']&.strip}"
      unit
    end

    def available_items
      return @available_items if @available_items

      @available_items = {}
      # Prepare a list of the shipped items of the order
      shipped_units.each do |unit|
        (@available_items[unit.line_item_id.to_s] ||= []) << {
          inv: unit.id,
          stock_location_id: unit.line_item.vendor.stock_location.id
        }
      end
      @available_items
    end

    def check_authorization(authorization, items)
      if authorization.valid?
        context.authorizations << authorization
        Spree::LogEntry.create source: authorization, details: context.request.to_json
      else
        context.error_messages << (
          'Can\'t create RMA for items: ' + items.to_s + ' ' + authorization.errors.full_messages.join(', ')
        )
      end
      authorization
    end

    def check_errors
      context.fail!(error: context.error_messages.join('; ')) if context.error_messages.any?
      context.fail!(error: 'No RMA created') if context.authorizations.empty?
    end

    def create_authorization(items, stock_location, reason, comments)
      authorization = Spree::ReturnAuthorization.create(
        order: context.order,
        memo: "Narvar return - #{comments}",
        reason: reason,
        stock_location_id: stock_location,
        return_items_attributes: items.map { |item| { inventory_unit_id: item, return_reason_id: reason.id } },
        gift_recipient_email: gift_recipient_email,
        tracking_url: tracking_url
      )
      register_easypost_tracker(authorization)
      check_authorization(authorization, items)
    end

    def gift_recipient_email
      return unless context.request['gift']

      context.request['email']
    end

    def tracking_url
      context.request.dig('package', 'tracking_url')
    end

    def tracking_number
      context.request.dig('package', 'tracking_number')
    end

    def carrier
      context.request.dig('package', 'carrier')
    end

    def register_easypost_tracker(authorization)
      return unless authorization.persisted?

      context = ::Easypost::CreateTrackerInteractor.call(tracking_code: tracking_number,
                                                         carrier: carrier,
                                                         return_authorization: authorization)
      return if context.tracker.blank?

      create_easypost_tracker(authorization)
    end

    def create_easypost_tracker(authorization)
      params = { carrier: carrier, tracking_code: tracking_number, spree_return_authorization_id: authorization.id }
      tracker = Easypost::Tracker.create(params)

      return if tracker.valid?

      Sentry.capture_message(I18n.t('errors.easypost.trackers.unable_to_create'),
                             extra: {
                               carrier: carrier,
                               tracking_code: tracking_number,
                               spree_return_authorization_id: authorization.number
                             })
    end

    def prepare_context
      context.authorizations = []
      context.error_messages = []
    end

    def prepare_items(items)
      return_items = []
      items.each do |item|
        line_item_id = item['item_id']
        units = available_items[line_item_id] || []
        quantity = item['quantity'].to_i
        units.first(quantity).each do |unit|
          next if return_items.include? unit

          return_items << add_unit(unit, item)
        end
      end
      context.fail!(error: 'No valid shipped items to return') if return_items.empty?
      return_items.group_by { |i| i[:stock_location_id] }
    end

    def process_items(return_items)
      return_items.each do |stock, items|
        items.group_by { |i| i[:reason] }.each do |reason, items2|
          item_ids = items2.map { |u| u[:inv] }
          comments = items2.map { |i| i[:comment] }.compact.join(', ')
          create_authorization(item_ids, stock, reason, comments)
        end
      end
    end

    def shipped_units
      context.order.inventory_units.shipped.sort_by do |unit|
        unit.line_item.vendor.stock_location.id
      end
    end

    def validate_context
      context.fail!(error: 'Order required') if context.order.blank?
      context.fail!(error: 'Request data required') if context.request.blank?
      context.fail!(error: 'No items in request') unless context.request['items']&.any?
    end
  end
end
