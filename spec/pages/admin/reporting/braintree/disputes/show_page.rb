# frozen_string_literal: true

module Admin
  module Reporting
    module Braintree
      module Disputes
        class ShowPage < SitePrism::Page
          set_url '/admin/reporting/braintree/disputes/{id}'

          section :content_header, Admin::ContentHeaderSection, '#content-header'
        end
      end
    end
  end
end
