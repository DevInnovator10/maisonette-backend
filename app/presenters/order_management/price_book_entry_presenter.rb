# frozen_string_literal: true

module OrderManagement
  class PriceBookEntryPresenter
    def initialize(price)
      @price = price
    end

    def payload
      {
        IsActive: !@price.discarded?,
        UnitPrice: @price.amount,
        Pricebook2Id: Maisonette::Config.fetch('order_management.pricebook2_id'),
        Product2Id: product_entity_ref
      }
    end

    private

    def product_entity_ref
      OrderManagement::Product.find_by!(order_manageable: @price.offer_settings).order_management_entity_ref
    end
  end
end
