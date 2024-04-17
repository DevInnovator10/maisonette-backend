# frozen_string_literal: true

module Mirakl
  module PostSubmitOrder
    class CalculateLeadTimeToShipInteractor < ApplicationInteractor
      helper_methods :created_date, :shipment

      def call
        context.ship_by = if created_date.weekday?
                            weekday
                          else
                            weekend
                          end
      rescue StandardError => e
        error_message = "Order number: #{shipment.order.number}\nShipment Number: #{shipment.number}"
        rescue_and_capture(e, error_details: error_message)
      end

      private

      def weekday
        if created_date.strftime('%H%M') < mirakl_shop.fulfil_by_eod_cutoff_time
          if created_date.strftime('%H%M') < shop_start_time
            weekday_before_cutoff_and_shop_start
          else
            weekday_before_cutoff_after_shop_start
          end
        else
          weekday_after_cutoff
        end
      end

      def weekend
        lead_days
          .business_days
          .after(created_date.next_week(:monday))
          .change(hour: shop_start_time[0...2],
                  min: shop_start_time[2...4])
      end

      def weekday_before_cutoff_and_shop_start
        lead_days.business_days.after(created_date).change(hour: shop_start_time[0...2],
                                                           min: shop_start_time[2...4])
      end

      def weekday_before_cutoff_after_shop_start
        lead_days.business_days.after(created_date).change(hour: created_date.strftime('%H'),
                                                           min: created_date.strftime('%M'))
      end

      def weekday_after_cutoff
        lead_days.business_days.after(created_date).end_of_day
      end

      def mirakl_shop
        shipment.mirakl_shop
      end

      def max_variant_lead
        @max_variant_lead ||= begin
          default_lead_time = MIRAKL_DATA[:order][:default_lead_time_to_ship]
          max_variant_lead = shipment.manifest.map do |item|
            monogram_lead_time = item.line_item.offer_settings&.monogram_lead_time.to_i
            variant_lead_time = item.variant.lead_time.to_i
            monogram_lead_time + variant_lead_time
          end.max
          max_variant_lead = default_lead_time unless max_variant_lead >= default_lead_time
          max_variant_lead
        end
      end

      def leniency_days
        shipment.mirakl_shop.lead_time_ship_leniency
      end

      def lead_days
        leniency_days + max_variant_lead

      end

      def shop_start_time
        @shop_start_time ||= mirakl_shop.working_hr_start_time.rjust(4, '0')
      end
    end
  end
end
