# frozen_string_literal: true

wished_product ||= @wished_product

json.partial! 'spree/api/wished_products/wished_product', wished_product: wished_product
