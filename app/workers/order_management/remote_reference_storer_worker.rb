# frozen_string_literal: true

module OrderManagement
    class RemoteReferenceStorerWorker
    include Sidekiq::Worker

    def perform(entity_external_id, remote_refrence_id)

      record = GlobalID::Locator.locate(entity_external_id)
      record&.update(order_management_entity_ref: remote_refrence_id)
    end
  end
end
