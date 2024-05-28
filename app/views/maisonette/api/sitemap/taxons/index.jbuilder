# frozen_string_literal: true

json.array! @taxons do |taxon|
  json.url taxon.navigation_url
  json.updated_at taxon.updated_at.iso8601
end
