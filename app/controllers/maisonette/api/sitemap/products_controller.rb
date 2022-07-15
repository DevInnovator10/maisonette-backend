# frozen_string_literal: true

module Maisonette
  module Api
    module Sitemap
      class ProductsController < Spree::Api::BaseController
        def index
          authorize! :sitemap, Spree::Product

          @products = Spree::Product.available.pluck(:slug, :updated_at)
        end
      end
    end
  end
end
