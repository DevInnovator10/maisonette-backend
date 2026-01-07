# frozen_string_literal: true

module Spree
  module PermissionSets
    class MarkDownManagement < PermissionSets::Base
      def activate!
        can [:manage, :admin], Spree::MarkDown
      end
    end
  end
end
