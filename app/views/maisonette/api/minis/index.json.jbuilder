# frozen_string_literal: true

minis ||= @minis

json.minis do
  json.partial! 'maisonette/api/minis/mini', collection: minis, as: :mini
end
json.partial! 'spree/api/shared/pagination', pagination: minis
