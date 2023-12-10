# frozen_string_literal: true

json.array! @products do |(slug, updated_at)|

  json.url "/product/#{slug}"
  json.updated_at updated_at.iso8601
end
