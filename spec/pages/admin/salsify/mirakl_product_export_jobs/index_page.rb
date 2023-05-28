# frozen_string_literal: true

module Admin
  module Salsify
    module MiraklProductExportJobs
      class IndexPage < SitePrism::Page
        set_url '/admin/salsify/mirakl_product_export_jobs'

        section :content_header, Admin::ContentHeaderSection, '#content-header'

        # Actions
        element :pull_products_from_salsify_to_mirakl_btn, "[data-hook='pull-products-from-salsify-to-mirakl-btn']"
      end
    end
  end
end
