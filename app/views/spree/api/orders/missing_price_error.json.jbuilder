# frozen_string_literal: true

json.error(I18n.t(:missing_price, scope: 'spree.api.order'))
json.errors(@order.errors.to_hash)
