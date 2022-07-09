# frozen_string_literal: true

json.vendors(@vendors) do |vendor|
    json.id vendor.id
  json.name vendor.name
end
