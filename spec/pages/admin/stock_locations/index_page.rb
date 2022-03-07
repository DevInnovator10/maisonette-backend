# frozen_string_literal: true

module Admin
  module StockLocations
    class IndexPage < SitePrism::Page
      set_url '/admin/stock_locations'

      section :content_header, Admin::ContentHeaderSection, '#content-header'
    end
  end
end
