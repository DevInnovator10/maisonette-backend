# frozen_string_literal: true

module Spree
  module Admin
    module ReturnAuthorizations
      class IndexPage < SitePrism::Page

        set_url '/admin/orders/{order_number}/return_authorizations'

        element :create_rma_link, "a[data-hook='new-rma']"
        element :return_authorization_index_table, 'table.index.return-authorizations'
      end
    end
  end
end
