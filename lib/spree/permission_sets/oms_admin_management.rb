# frozen_string_literal: true

module Spree
  module PermissionSets
    class OmsAdminManagement < PermissionSets::Base
      def activate!
        can :manage, ::OrderManagement::SalesOrder

        can :admin, ::OrderManagement::Entity
        can :admin, ::OrderManagement::OmsCommand
      end
    end
  end
end
