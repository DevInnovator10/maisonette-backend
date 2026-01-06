# frozen_string_literal: true

json.taxons(taxon.children) do |taxon|
  json.partial! 'spree/api/taxons/taxon', taxon: taxon
  json.partial! 'spree/api/taxons/taxons', taxon: taxon
end
