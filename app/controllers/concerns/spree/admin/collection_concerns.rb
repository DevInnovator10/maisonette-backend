# frozen_string_literal: true

module Spree
  module Admin
    module CollectionConcerns
      extend ActiveSupport::Concern

      private

      def collection(model)
        @collection = model.all

        params[:q] ||= {}

        @search = @collection.ransack(params[:q])

        @collection = @search.result.page(params[:page]).per(
          params[:per_page] || Spree::Config[:orders_per_page]
        )
      end
    end
  end
end
