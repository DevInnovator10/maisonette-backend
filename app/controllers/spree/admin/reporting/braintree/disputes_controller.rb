# frozen_string_literal: true

module Spree
  module Admin
    module Reporting
      module Braintree
        class DisputesController < Spree::Admin::ResourceController
          private

          def collection
            return @collection if @collection

            params[:q] ||= {}
            @search = super.ransack(params[:q])

            @collection = @search.result(distinct: true)
                                 .page(params[:page])
                                 .per(params[:per_page])
                                 .order(id: :desc)
                                 .includes(spree_payment: :order)
          end

          def model_class
            ::Reporting::Braintree::Dispute
          end
        end
      end
    end
  end
end
