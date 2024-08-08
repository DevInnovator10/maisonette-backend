# frozen_string_literal: true

module Spree
  module PermissionSets
    class MigrationLogDisplay < PermissionSets::Base
      def activate!
        can [:read, :admin], Migration::Log
      end
    end
  end
end
