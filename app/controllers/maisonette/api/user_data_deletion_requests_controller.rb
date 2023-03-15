# frozen_string_literal: true

module Maisonette
  module Api
    class UserDataDeletionRequestsController < Spree::Api::BaseController
      def create
        @deletion_request = UserDataDeletionRequest.new user: current_api_user,
                                                        email: current_api_user.email

        if @deletion_request.save
          Maisonette::UserDataDeletionRequestWorker.perform_async(@deletion_request.id)

          render json: @deletion_request, status: :created
        else
          render json: @deletion_request.errors, status: :unprocessable_entity
        end
      end
    end
  end
end
