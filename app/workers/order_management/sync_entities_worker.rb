# frozen_string_literal: true

module OrderManagement
  class SyncEntitiesWorker
    include Sidekiq::Worker

    BY_PER_MINUTE_REQUEST_LIMIT = 25

    sidekiq_options lock: :while_executing, conflict_strategy: :reject, queue: 'default'

    def perform(type)
      OrderManagement::Entity.out_of_sync.where(type: type).order(updated_at: :desc)
                             .first(BY_PER_MINUTE_REQUEST_LIMIT)
                             .each(&:sync_order_management!)
    end
  end
end
