# frozen_string_literal: true

json.error(I18n.t(:insufficient_stock, scope: 'spree.api.order'))
json.errors(@order.line_items.map { |li| li.errors.to_hash })
