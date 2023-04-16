# frozen_string_literal: true

module Spree
  module Admin
    class MigrationLogsController < BaseController
      before_action :taxons_report

      def index
        @migrable_types = Migration::Log.group(:migrable_type).count
        collection(Migration::Log.all.order(id: :desc))
        respond_with(@collection)
      end

      def show
        @log = Migration::Log.find(params[:id])
        @related_logs = related_logs
        collection(@log.order? ? @log.components.order(migrable_type: :asc, id: :desc) : Migration::Log.none)
      end

      def taxons
        send_data(taxons_report, filename: 'missing_taxons.csv')
      end

      def fixed
        log = Migration::Log.find(params[:id])
        log.update!(status: :fixed)

        redirect_back(fallback_location: admin_migration_log_path(log))
      end

      private

      def collection(list)
        params[:q] ||= {}
        @search = list.ransack(params[:q])
        @collection = @search.result.page(params[:page]).per(params[:per_page] || Spree::Config[:orders_per_page])
      end

      def model_class
        ::Migration::Log
      end

      def related_logs
        return unless @log.migrable_type == 'Legacy::Spree::Promotion'

        Migration::Log.where(legacy_id: @log.legacy_id, migrable_type: 'Legacy::Spree::Promotion').page(params[:page])
                      .where.not(id: @log.id)
                      .per(params[:per_page] || Spree::Config[:promotions_per_page])
      end

      def taxons_report
        @taxons_report ||= redis.get('missing_taxons')
      end

      def redis
        @redis ||= Redis.new(url: redis_url)
      end

      def redis_url
        "#{::Maisonette::Config.fetch('redis.service_url')}/#{::Maisonette::Config.fetch('redis.db')}"
      end
    end
  end
end
