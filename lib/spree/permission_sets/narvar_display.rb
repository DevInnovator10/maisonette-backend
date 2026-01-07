# frozen_string_literal: true

module Spree
  module PermissionSets
    class NarvarDisplay < PermissionSets::Base
      def activate!
        can [:read, :admin], Narvar::Order
      end
    end
  end
end
