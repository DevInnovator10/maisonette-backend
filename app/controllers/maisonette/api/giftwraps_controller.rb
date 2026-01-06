# frozen_string_literal: true

module Maisonette
  module Api
    class GiftwrapsController < Spree::Api::BaseController
      before_action :find_shipment

      def create
        new_giftwrap = @shipment.build_giftwrap

        authorize! :crud, new_giftwrap, order_token

        if new_giftwrap.save
          render :show, locals: { giftwrap: new_giftwrap }, status: :created
        else
          invalid_resource! new_giftwrap
        end
      end

      def destroy
        authorize! :crud, giftwrap, order_token
        giftwrap.destroy!
        render json: giftwrap, status: :no_content
      end

      private

      def giftwrap
        @giftwrap ||= @shipment.giftwrap
      end

      def find_shipment
        if @order.present?
          @shipment = @order.shipments.find_by!(number: params[:shipment_id])
        else
          @shipment = Spree::Shipment.readonly(false).find_by!(number: params[:shipment_id])
          @order = @shipment.order
        end
      end
    end
  end
end
