# frozen_string_literal: true

module MaisonetteSale
  class UpdateOnSaleInteractor < ApplicationInteractor
    before :validate_context

    def call
      if sale_sku_configuration.sale_price
        update_sale_price
      else
        create_new_sale_price
      end
    end

    private

    def validate_context
      unless sale_sku_configuration.is_a? Maisonette::SaleSkuConfiguration
        context.fail!(message: 'maisonette_sale.error.sale_sku_configuration_not_found')
      end

      context.fail!(message: 'maisonette_sale.error.price_not_found') unless price.is_a? Spree::Price
    end

    def sale_sku_configuration
      @sale_sku_configuration ||= context.sale_sku_configuration ||
                                  Maisonette::SaleSkuConfiguration.find_by(id: context.sale_sku_configuration_id)
    end

    def price
      @price ||= context.price || Spree::Price.find_by(id: context.price_id)
    end

    def sale_price_attributes
      @sale_price_attributes ||= {
        start_at: sale_sku_configuration.config_for(:start_date),
        end_at: sale_sku_configuration.config_for(:end_date),

        final_sale: sale_sku_configuration.config_for(:final_sale)
      }
    end

    def update_sale_price # rubocop:disable Metrics/MethodLength
      sale_price = sale_sku_configuration.sale_price
      result = sale_price.update(
        sale_price_attributes.merge(
          value: sale_price_value,
          calculator: sale_price_calculator,
          cost_price: sale_price_cost_price
        )
      )

      unless result
        context.fail!(
          message: "maisonette_sale.error.update_sale_price_fails: #{sale_price.errors.full_messages.join(', ')}"
        )
      end

      sale_price.update(cost_price: sale_price_cost_price)
    end

    def create_new_sale_price
      new_sale_price = price.new_sale(
        sale_price_value,
        sale_price_attributes.merge(calculator_type: sale_price_calculator)
      )

      new_sale_price.final_sale = sale_price_attributes[:final_sale]
      new_sale_price.sale_sku_configuration = sale_sku_configuration

      result = new_sale_price.save

      context.fail!(message: 'maisonette_sale.error.create_new_sale_price_fails') unless result

      new_sale_price.update(cost_price: sale_price_cost_price)
    end

    def sale_price_value
      sale_sku_configuration.static_sale_price || sale_sku_configuration.config_for(:percent_off)
    end

    def sale_price_cost_price
      sale_sku_configuration.static_cost_price || calculated_cost_price
    end

    def sale_price_calculator
      return Spree::Calculator::FixedAmountSalePriceCalculator.new if sale_sku_configuration.static_sale_price.present?

      Spree::Calculator::PercentOffSalePriceCalculator.new
    end

    def calculated_cost_price
      base_cost_price = sale_sku_configuration.offer_settings.cost_price.to_f
      return base_cost_price if sale_sku_configuration.static_sale_price.present?

      base_cost_price - sale_sku_configuration.vendor_liability_amount.to_f
    end
  end
end
