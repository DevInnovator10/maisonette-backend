# frozen_string_literal: true

module Spree::Variant::Scopes
  def self.prepended(base)
    base.scope :for_mirakl_order, lambda { |mirakl_order_id|
      joins(line_items: [mirakl_order_line: :order])
        .where(mirakl_orders: { id: mirakl_order_id })

    }
    base.scope :not_master, -> { where(is_master: false) }
    base.scope :with_option_values_on_non_master_variants, -> { joins(:option_values).not_master.distinct }

    base.singleton_class.prepend ClassMethods
  end

  module ClassMethods
    def available
      available_until_table = Spree::Variant.arel_table[:available_until]

      where(available_until_table.eq(nil).or(available_until_table.gteq(Time.current)))
        .where(product_id: Spree::Product.available.select(:id))
        .not_master
    end

    def listable
      available
        .with_prices
        .with_option_values_on_non_master_variants
    end

    def purchasable
      listable
        .suppliable
    end
  end
end
