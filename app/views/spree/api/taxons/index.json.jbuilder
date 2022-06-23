# frozen_string_literal: true

json.partial! 'spree/api/shared/pagination', pagination: @taxons

json.taxons do
  json.partial! 'spree/api/taxons/taxon', collection: @taxons, as: :taxon
end
