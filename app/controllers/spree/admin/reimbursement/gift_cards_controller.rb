# frozen_string_literal: true

module Spree
  module Admin
    module Reimbursement
      class GiftCardsController < Spree::Admin::ResourceController
        def send_email
          ::Narvar::ReturnsRmaMailer.gift_card_email(reimbursement_gift_card_id: @gift_card.id).deliver_later

          flash[:success] = flash_message_for(@gift_card, :successfully_updated)
          redirect_back(fallback_location: admin_order_reimbursements_path(@gift_card.reimbursement))
        end

        private

        def model_class
          Spree::Reimbursement::GiftCard
        end
      end
    end
  end
end
