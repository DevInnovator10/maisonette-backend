# frozen_string_literal: true

module Spree
    module Admin
    module Returns
      class CustomerReturnsController < Spree::Admin::BaseController
        include CollectionConcerns

        def index
          collection(Spree::CustomerReturn).order! 'created_at DESC'
        end
      end
    end
  end
end
