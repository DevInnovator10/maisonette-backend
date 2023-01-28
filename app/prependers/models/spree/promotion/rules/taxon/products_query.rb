# frozen_string_literal: true

module Spree::Promotion::Rules::Taxon::ProductsQuery
  def products_query(scope)
    case preferred_match_policy
    when 'any', 'all'
      scope.joins(:classifications).where(spree_products_taxons: { taxon_id: rule_taxon_ids_with_children })
    when 'none'
      excluded_ids = Spree::Classification.select(:product_id).where(taxon_id: rule_taxon_ids_with_children).distinct
      scope.where("#{Spree::Product.table_name}.id NOT IN (:excluded_ids)", excluded_ids: excluded_ids)
    else
      raise "unexpected match policy: #{preferred_match_policy.inspect}"
    end
  end
end
