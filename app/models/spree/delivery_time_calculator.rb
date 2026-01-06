# frozen_string_literal: true

module Spree
  class DeliveryTimeCalculator
    STANDARD_SHIPPING_DELIVERY_TIME = 5
    STANDARD_SHIPPING_GRACE_PERIOD = 3

    def initialize(shipment, start_date = nil)
      @shipment = shipment
      @line_items = shipment.line_items
      @start_date = calculate_start_date(start_date)
      @estimation = build_estimation
    end

    def to_s
      @estimation.map { |e| DeliveryTimeCalculator.delivery_date_format(e) }.join(' - ')
    end

    class << self
      def standard_shipping_estimation(variant)
        raise ArgumentError unless variant.is_a? ::Spree::Variant

        days = [
          variant.lead_time + STANDARD_SHIPPING_DELIVERY_TIME,
          variant.lead_time + STANDARD_SHIPPING_DELIVERY_TIME + STANDARD_SHIPPING_GRACE_PERIOD
        ]
        estimation = days.map do |d|
          d.business_days.after(Time.current)
        end

        estimation.map { |e| delivery_date_format(e) }.join(' - ')
      end

      def delivery_date_format(date)
        date.try(:strftime, '%b %d') || ''
      end
    end

    private

    def calculate_start_date(start_date)
      backorder_date = @line_items.detect(&:backorder_date)&.backorder_date
      return backorder_date.in_time_zone if @shipment.backordered? && backorder_date&.>(Time.zone.now)

      start_date&.in_time_zone || Time.zone.now
    end

    def build_estimation
      return [] unless shipping_method

      days = build_day_period_array
      days.map { |d| d.business_days.after(@start_date) }
    end

    def build_day_period_array
      return [] if @line_items.blank?

      lead_time = max_line_item_lead_time
      [min_days(lead_time), max_days(lead_time)].uniq
    end

    def max_line_item_lead_time
      [
        @line_items.joins(:variant).maximum(:lead_time),
        @line_items.joins(:monogram, variant: :offer_settings).maximum(:monogram_lead_time)
      ].compact.max ||
        Maisonette::Config.fetch('store_defaults.default_lead_time')
    end

    def min_days(lead_time)
      lead_time + min_delivery_days
    end

    def max_days(lead_time)
      lead_time + max_delivery_days
    end

    def min_delivery_days
      shipping_method.delivery_time.to_i
    end

    def max_delivery_days
      shipping_method.delivery_time.to_i + shipping_method.grace_period.to_i
    end

    def shipping_method
      @shipping_method ||= @shipment.selected_shipping_rate&.shipping_method
    end
  end
end
