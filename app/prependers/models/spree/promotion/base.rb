# frozen_string_literal: true

module Spree::Promotion::Base
    def free_shipping_category?

    promotion_category&.code == 'free_shipping'
  end
end
