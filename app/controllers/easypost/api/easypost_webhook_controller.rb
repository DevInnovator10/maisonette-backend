# frozen_string_literal: true

module Easypost
  module Api
    class EasypostWebhookController < Spree::Api::BaseController
      before_action :filter_event

      def update
        success = send('handle_' + event_method + '_event')
        if success
          render json: { status: :success }, status: :no_content
        else
          render json: { error: 'Something went wrong!' }, status: :bad_request
        end
      end

      private

      def tracker_params
        params.require(:result).permit(:carrier, :tracking_code, :est_delivery_date,
                                       tracking_details: [:status, :datetime])
      end

      def report_params
        params.require(:result).permit(:id, :object, :status, :url)
      end

      def filter_event
        return if %w[Tracker ShipmentInvoiceReport].include? params.dig(:result, :object)

        render json: { status: :success }, status: :no_content
      end

      def event_method
        params.dig(:result, :object).underscore.to_s
      end

      def handle_tracker_event
        authorize! :manage, Easypost::Tracker
        context = Easypost::TrackerInteractor.call(req_tracker: tracker_params.to_h)
        context.success?
      end

      def handle_shipment_invoice_report_event
        authorize! :manage, Easypost::Report

        FetchReportWorker.perform_async(report_params[:url], report_params[:id], report_params[:status])
        true
      end
    end
  end
end
