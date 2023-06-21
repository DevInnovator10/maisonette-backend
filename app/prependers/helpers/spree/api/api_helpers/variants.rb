# frozen_string_literal: true

module Spree::Api::ApiHelpers::Variants
  # @@variant_attributes = [:id, :name, :sku, :weight, :is_master, :slug, :description, :track_inventory]
  def self.prepended(base) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    base.variant_attributes.delete(:height)
    base.variant_attributes.delete(:width)
    base.variant_attributes.delete(:depth)
    base.variant_attributes.delete(:weight)

    base.module_eval do # rubocop:disable Metrics/BlockLength
      def display_product_dimension(dimension)
        return if dimension.blank?

        display_dimension(dimension, '"')
      end

      def display_product_weight(weight)
        return if weight.blank? || weight.zero?

        display_dimension(weight, ' lbs')
      end

      def total_on_hand_with_prices_for(variant)
        total_on_hand_with_prices = variant.prices.sum(&:total_on_hand)
        if total_on_hand_for(variant)&.positive? && total_on_hand_with_prices.zero?
          notify_slack(variant)
        end

        total_on_hand_with_prices
      end

      def notify_slack(variant)
        channel = 'variant-inventory-price-mismatch-alert'
        slack_message = "Total stock of this variant with prices are zero:
                         Product slug: #{variant.product.slug}
                         Variant sku: #{variant.sku}"
        Maisonette::Slack.notify(channel: channel, payload: slack_message)
      end

      def variant_in_stock?(variant)
        variant.prices.sum(&:total_on_hand).positive?
      end

      private

      def display_dimension(dimension, unit)
        "#{Spree::LocalizedNumber.parse(dimension.to_s)}#{unit}"
      end
    end
  end
end
