# frozen_string_literal: true

module Salsify
  class MarkDiscontinuedInteractor < ApplicationInteractor
    before :validate_context, :prepare_context

    def call
      if product_action?
        product.update(available_until: Time.zone.today) unless context.pdp_variant_enabled
      elsif variant_action?
        offer_settings.discard
      else
        product.update(available_until: nil) if product.available_until
        offer_settings.undiscard
      end
      context.product = product
    end

    private

    def prepare_context
      context.offer_settings = Spree::OfferSettings.find_by(maisonette_sku: row['Maisonette SKU'])

      context.fail!(messages: "#{self.class.name} - offer settings not found") if offer_settings.nil?
    end

    def validate_context
      context.fail!(messages: "#{self.class.name} cannot discontinue without row") if row.nil?
      context.fail!(messages: "#{self.class.name} cannot discontinue without action value") if action.nil?
    end

    def product_action?
      action == 'PD'
    end

    def variant_action?
      action == 'VD'
    end

    def offer_settings
      context.offer_settings
    end

    def product
      offer_settings.variant.product
    end

    def row
      context.row
    end

    def action
      context.action
    end
  end
end
