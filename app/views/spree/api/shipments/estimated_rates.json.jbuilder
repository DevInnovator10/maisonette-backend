# frozen_string_literal: true

json.shipping_rates @shipping_rates do |shipping_rate|
  json.call(shipping_rate, :admin_name, :cost, :shipping_method_id, :shipping_method_code, :extra_cost, :total_cost)
end
