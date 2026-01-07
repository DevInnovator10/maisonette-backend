# frozen_string_literal: true

module Spree::Payment::AsyncAvalaraFinalize
  def avalara_finalize
    return unless avalara_tax_enabled?

    Spree::AvalaraFinalizeOrderWorker.perform_async(order.number)
  end
end
