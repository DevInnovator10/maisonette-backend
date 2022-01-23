# frozen_string_literal: true

module Spree
  module PermissionSets
    class TaxonomyManagement < PermissionSets::Base
      def activate!
        can [:manage, :admin], Spree::Taxonomy
        can [:manage, :admin], Spree::Taxon
      end
    end
  end
end
