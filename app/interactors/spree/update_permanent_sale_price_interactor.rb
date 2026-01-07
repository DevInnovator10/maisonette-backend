# frozen_string_literal: true

module Spree
    class UpdatePermanentSalePriceInteractor < ApplicationInteractor
    helper_methods :offer_settings

    def call
      return unless price

      if permanent_sale_price.to_f.zero?
        destroy_permanent_sale_price
      else
        update_permanent_sale_price
      end
    rescue StandardError => e
      rescue_and_capture(e, extra: { offer_settings: offer_settings&.attributes })
    end

    private

    def update_permanent_sale_price
      sale_price = price.sale_prices.find_or_initialize_by(permanent: true)
      return if sale_price.value == permanent_sale_price

      sale_price.update!(enabled: true,
                         value: permanent_sale_price,
                         calculator: Spree::Calculator::FixedAmountSalePriceCalculator.new,
                         start_at: Time.current)
      update_mark_downs
    end

    def destroy_permanent_sale_price
      destroyed = price.sale_prices.find_by(permanent: true)&.destroy!
      update_mark_downs if destroyed
    end

    def price
      offer_settings.price
    end

    def permanent_sale_price
      offer_settings.permanent_sale_price
    end

    def update_mark_downs
      price.save!
    end
  end
end
