# frozen_string_literal: true

module Spree
  module Admin
    class GiftCardsController < Spree::Admin::ResourceController
      def update
        result = ::Maisonette::GiftCardGeneratorOrganizer.call(permitted_resource_params.merge(gift_card: @gift_card))
        if result.success?
          flash[:success] = flash_message_for(@gift_card, :successfully_updated)
          redirect_to(edit_admin_gift_card_path(@gift_card))
        else
          flash.now[:error] = result.error
          render_after_update_error
        end
      end

      def send_gift_card_email
        Spree::GiftCardMailer.send_gift_card(@gift_card).deliver_now
        flash[:success] = flash_message_for(@gift_card, :successfully_updated)
        redirect_to edit_admin_gift_card_path(@gift_card)
      end

      def send_confirmation_email
        Spree::GiftCardMailer.send_confirmation(@gift_card).deliver_now
        flash[:success] = flash_message_for(@gift_card, :successfully_updated)
        redirect_to(edit_admin_gift_card_path(@gift_card))
      end
    end
  end
end
