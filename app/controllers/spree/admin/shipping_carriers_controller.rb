# frozen_string_literal: true

module Spree
  module Admin
    class ShippingCarriersController < Spree::Admin::BaseController

      def index
        params[:q] ||= {}
        @search = Spree::ShippingCarrier.ransack(params[:q])
        @shipping_carriers = @search.result(distinct: true)
                                    .page(params[:page])
                                    .per(params[:per_page] || Spree::Config[:orders_per_page])
                                    .order(id: :desc)

        @service_levels = load_service_levels
        @enabled_shipping_service_levels = current_store.enabled_shipping_service_levels
      end

      def update_service_levels
        if params[:service_levels].present?
          list = params[:service_levels].sort { |a, b| a.tr('|', ' ') <=> b.tr('|', ' ') }
          service_levels = list.map do |service_level|
            service_level.split('|', 2)
          end
          current_store.update(enabled_shipping_service_levels: service_levels)
        end

        redirect_back(fallback_location: admin_shipping_carriers_path)
      end

      private

      def load_service_levels
        rate_services = ::Easypost::Order.group(:rate_carrier, :rate_service).count
        service_levels = rate_services.map do |(carrier, service), _cnt|
          ["#{carrier} - #{service}", "#{carrier}|#{service}"]
        end
        service_levels.sort!
      end
    end
  end
end
