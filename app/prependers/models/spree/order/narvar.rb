# frozen_string_literal: true

module Spree::Order::Narvar
  def self.prepended(base)
    base.has_one :narvar_order,
                 class_name: 'Narvar::Order',
                 dependent: :nullify,
                 inverse_of: :spree_order,
                 foreign_key: :spree_order_id

    base.state_machine do
      after_transition to: %i[complete resumed canceled], do: :narvar_update_data
    end
    base.after_commit :narvar_update_data, if: :order_shippment_status_changed?
  end

  def narvar_update_data
    return unless narvar_api_url?

    ::Narvar::SyncOrderWorker.perform_async(number)
  end

  private

  def narvar_api_url?
    @narvar_api_url ||= Maisonette::Config.fetch('narvar.api_url').present?
  end

  def order_shippment_status_changed?
    (shipped? || shipment_state == 'partial') && saved_change_to_shipment_state?
  end
end
