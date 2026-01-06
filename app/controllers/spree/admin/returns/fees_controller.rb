# frozen_string_literal: true

module Spree
  module Admin
    module Returns
      class FeesController < Spree::Admin::BaseController
        include CollectionConcerns

        def index
          collection(::Maisonette::Fee.order(created_at: :desc))
        end
      end
    end
  end
end
