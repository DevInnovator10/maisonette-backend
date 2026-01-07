# frozen_string_literal: true

module Spree
  module PermissionSets
    class GiftwrapsManagement < PermissionSets::Base
      def activate!
        can :crud, Maisonette::Giftwrap do |giftwrap, guest_token|
          user&.admin? ||
            giftwrap.shipment.order.user == user ||
            giftwrap.shipment.order.guest_token == guest_token
        end
      end
    end
  end
end
