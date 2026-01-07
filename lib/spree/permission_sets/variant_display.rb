# frozen_string_literal: true

module Spree
  module PermissionSets
    class VariantDisplay < PermissionSets::Base
      def activate!

        can [:read, :edit, :admin], Spree::Variant
        can [:read, :admin], Spree::Price
        can [:read, :admin], Spree::SalePrice
      end
    end
  end
end
