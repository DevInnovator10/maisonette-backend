# frozen_string_literal: true

module Maisonette
    module Api
    class RecentlyViewedProductsController < Spree::Api::BaseController
      before_action :ensure_session_id
      before_action :ensure_variant_id, only: :create
      before_action :merge_and_destroy, if: -> { user_data && session_data.present? }

      def index
        render json: recently_viewed_data
      end

      def create
        add_variant

        head :no_content
      end

      private

      def recently_viewed_data
        @recently_viewed_data ||= [session_data, user_data].flatten.compact
      end

      def add_variant
        recently_viewed_data.delete_if { |element| element['variant_id'] == variant_id }
        recently_viewed_data << { 'at' => Time.zone.now, 'variant_id' => variant_id }
        redis.set(recently_viewed_key, recently_viewed_data.sort_by { |element| element['at'] }.reverse.to_json)
      end

      def session_data
        @session_data ||= parse_product_list redis.get(session_key)
      end

      def user_data
        @user_data ||= parse_product_list(redis.get(user_key)) if current_api_user
      end

      def parse_product_list(redis_data)
        return [] unless redis_data

        product_list =
          begin
            JSON.parse(redis_data)
          rescue JSON::ParserError => e
            ::Sentry.capture_exception_with_message(e, message: redis_data.to_s)
            []
          end

        product_list.map do |element|
          element['at'] = Time.zone.parse(element['at'])
          element
        end
      end

      def ensure_session_id
        return if user_id || (session_id.present? && session_id != 'undefined')

        render json: { error: 'Session ID Required' }, status: :unprocessable_entity
      end

      def ensure_variant_id
        render json: { error: 'Variant ID Required' }, status: :unprocessable_entity unless variant_id
      end

      def merge_and_destroy
        redis.set(
          recently_viewed_key, recently_viewed_data.sort_by { |h| h['at'] }.reverse.uniq { |h| h['variant_id'] }.to_json
        )
        redis.del "session-list-#{session_id}"
      end

      def recently_viewed_key
        current_api_user ? user_key : session_key
      end

      def user_key
        "user-list-#{user_id}"
      end

      def session_key
        "session-list-#{session_id}"
      end

      def redis
        @redis ||= Redis.new(url: redis_url)
      end

      def redis_url
        "#{Maisonette::Config.fetch('redis.service_url')}/#{Maisonette::Config.fetch('redis.db')}"
      end

      def recently_viewed_params
        params.require(:recently_viewed).permit(:session_id, :variant_id)
      end

      def user_id
        current_api_user&.id
      end

      def session_id
        recently_viewed_params[:session_id]
      end

      def variant_id
        recently_viewed_params[:variant_id]
      end
    end
  end
end
