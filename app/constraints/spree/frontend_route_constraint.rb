# frozen_string_literal: true

module Spree
    class FrontendRouteConstraint
    SPREE_FRONTEND_ROUTES = %w[
      account
      cart
      cart_link
      checkout
      client_token
      configurations
      content/cvv
      locale/set
      login
      logout
      orders
      password/change
      password/recover
      products
      signup
      t/
      transactions
      unauthorized
      users
      user/spree_user
    ].freeze

    def matches?(request)
      SPREE_FRONTEND_ROUTES.any? { |route| request[:frontend_route].starts_with?(route) }
    end
  end
end
