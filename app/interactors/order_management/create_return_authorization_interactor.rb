# frozen_string_literal: true

module OrderManagement
  class CreateReturnAuthorizationInteractor < ApplicationInteractor
    before :validate_context

    def call
      ActiveRecord::Base.transaction do
        return_items = context.info.flat_map do |info|
          create_return_items(info)
        end.compact

        context.customer_return ||= build_customer_return(return_items.first.inventory_unit)
        context.customer_return.return_items = return_items
        context.customer_return.save!
      end
    end

    private

    def find_return_reason(external_id)
      GlobalID::Locator.locate(external_id)&.order_manageable
    end

    def create_return_items(info)
      quantity = info[:quantity].to_i
      line_item = find_line_item(info[:order_item_summary_ref])
      return nil if line_item.nil? || line_item.order != order

      quantity.times.map do |_|
        inventory_unit = find_inventory_unit(line_item)

        return_item = Spree::ReturnItem.from_inventory_unit(inventory_unit)
        return_item.return_reason = find_return_reason(info[:return_reason_external_id])
        return_item.return_authorization = return_authorization
        return_item.save!
        return_item
      end
    end

    def find_inventory_unit(line_item)
      line_item
        .inventory_units
        .joins('LEFT JOIN spree_return_items ON spree_return_items.inventory_unit_id = spree_inventory_units.id')
        .find_by!(state: 'shipped', spree_return_items: { id: nil })
    end

    def validate_context
      context.fail!(error: 'Missing order') if order.nil?
    end

    def build_customer_return(inventory_unit)
      context.customer_return = Spree::CustomerReturn.new(stock_location: inventory_unit.shipment.stock_location)
    end

    def return_authorization
      context.return_authorization ||= Spree::ReturnAuthorization.create!(
        order: order,
        stock_location: stock_location,
        return_reason_id: find_return_reason(context.return_reason_external_id)&.id,
        tracking_url: context.tracking_url
      )
    end

    def stock_location
      context.stock_location ||= context.info&.detect do |info|
        stock_location = find_line_item(info[:order_item_summary_ref])&.shipments&.first&.stock_location

        break stock_location if stock_location.presence
      end
    end

    def order
      context.order ||= context.info&.detect do |info|
        order = find_line_item(info[:order_item_summary_ref])&.order

        break order if order.presence
      end
    end

    def find_line_item(order_item_summary_ref)
      find_order_item_summary(order_item_summary_ref)&.summarable
    end

    def find_order_item_summary(order_item_summary_ref)
      OrderManagement::OrderItemSummary.find_by!(order_management_ref: order_item_summary_ref)
    rescue ActiveRecord::RecordNotFound => e
      Sentry.capture_exception_with_message(e, message: 'OrderItemSummary not found', extra: context)
      nil
    end
  end
end
