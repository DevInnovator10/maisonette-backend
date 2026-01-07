# frozen_string_literal: true

module Spree::Admin::PromotionCodesController::Actions
  def self.prepended(base)
    base.before_action :find_promotion, only: :create
  end

  def create
    if @promotion.gift_card?
      @promotion_code = @promotion.promotion_codes.build(value: params[:promotion_code][:value])
      if @promotion_code.save
        flash[:success] = flash_message_for(@promotion_code, :successfully_created)
        redirect_to edit_admin_gift_card_path(@promotion_code.gift_card)
      else
        flash.now[:error] = @promotion_code.errors.full_messages.to_sentence
        render_after_create_error
      end
    else
      super
    end
  end

  private

  def find_promotion
    @promotion = Spree::Promotion.accessible_by(current_ability, :show).find(params[:promotion_id])
  end
end
