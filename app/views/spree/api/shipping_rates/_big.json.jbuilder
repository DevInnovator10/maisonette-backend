# frozen_string_literal: true

json.call(shipping_rate, :id, :name, :admin_name, :cost, :selected, :shipping_method_id, :shipping_method_code,
          :extra_cost, :total_cost)
json.base_flat_rate_amount(shipping_rate.base_flat_rate_amount.to_f)
