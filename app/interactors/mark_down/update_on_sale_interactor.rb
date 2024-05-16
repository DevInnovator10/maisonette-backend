# frozen_string_literal: true

module MarkDown
    class UpdateOnSaleInteractor < ApplicationInteractor
    before do
      context.added_sale_prices = 0
      context.sale_prices = []
    end

    def call
      context.fail!(message: 'mark_down.error.mark_down_not_found') unless mark_down.is_a? Spree::MarkDown

      context.updated_sale_prices = sale_prices_to_update.update_all( # rubocop:disable Rails/SkipsModelValidations
        sale_price_attributes.merge(value: mark_down.amount, final_sale: mark_down.final_sale)
      )

      context.removed_sale_prices = sale_prices_to_remove.destroy_all.count

      put_prices_on_sale(prices_to_put_on_sale)
    end

    private

    def put_price_on_sale_for_mark_down(price, mark_down)
      new_sale_price = price.new_sale(
        mark_down.amount,
        sale_price_attributes.merge(calculator_type: Spree::Calculator::PercentOffSalePriceCalculator.new)
      )

      new_sale_price.final_sale = mark_down.final_sale

      new_sale_price.save!

      after_sale_price_save(new_sale_price)

      context.added_sale_prices += 1
    rescue StandardError => e
      message = { mark_down: mark_down, price: price }
      Sentry.capture_message("#{e.message}\n\n#{message}")
    end

    def after_sale_price_save(new_sale_price)
      mark_down.sale_prices << new_sale_price
      context.sale_prices << new_sale_price
    end

    def put_prices_on_sale(price_list)
      price_list.find_each do |price|
        put_price_on_sale_for_mark_down(price, mark_down)
      end
    end

    def sale_price_attributes
      @sale_price_attributes ||= {
        start_at: mark_down.start_at,
        end_at: mark_down.end_at,
        enabled: mark_down.active
      }
    end

    def mark_down
      @mark_down ||= context.mark_down || Spree::MarkDown.find_by(id: context.mark_down_id)
    end

    def price_ids_to_update
      @price_ids_to_update ||= context.price_ids_to_update || fetched_mark_down_price_ids
    end

    def fetched_mark_down_price_ids
      @fetched_mark_down_price_ids ||= mark_down.fetch_prices.pluck(:id)
    end

    def sale_prices_to_update
      sale_prices = mark_down.sale_prices.where(price_id: price_ids_to_update)
      context.sale_prices << sale_prices
      sale_prices
    end

    def sale_prices_to_remove
      if context.price_ids_to_update
        mark_down.sale_prices.where(price_id: context.price_ids_to_update - fetched_mark_down_price_ids)
      else
        mark_down.sale_prices.where.not(price_id: fetched_mark_down_price_ids)
      end
    end

    def prices_to_put_on_sale
      Spree::Price.where(id: (price_ids_to_update & fetched_mark_down_price_ids) - mark_down.prices.pluck(:id))
    end
  end
end
