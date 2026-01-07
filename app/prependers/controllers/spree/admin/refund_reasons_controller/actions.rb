# frozen_string_literal: true

module Spree::Admin::RefundReasonsController::Actions
  def sync_with_mirakl
    Mirakl::SyncReasonsInteractor.call!
    flash[:success] = 'Mirakl Refund Reasons Synced.'
    redirect_back fallback_location: admin_refund_reasons_path
  end
end
