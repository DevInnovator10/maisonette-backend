# frozen_string_literal: true

module OrderManagement
  class SyncEntityWorker
    include Sidekiq::Worker

    sidekiq_options lock: :while_executing, conflict_strategy: :reject, queue: 'default'

    def perform(entity_id)
      @entity = find_entity(entity_id)
      return unless @entity.class.sync_enabled? && !@entity.waiting_parent_forward?

      start_processing_entity
      @entity.class.advisory_lock(@entity.order_manageable) do
        set_entity_as_synced
        break if @entity.in_sync?

        context = OrderManagement::SyncInteractor.call(entity: @entity)
        context.success? ? update_entity!(context.order_management_entity_ref) : log_error!(context.error)
      end
    rescue StandardError => e
      log_error!(e.message)
    end

    private

    def log_error!(message)
      Rails.logger.error(I18n.t('order_management.sync_error', entity_type: @entity.type,
                                                               entity_id: @entity.id,
                                                               error_message: message))
      @entity.update!(
        sync_status: :out_of_sync,
        last_result: :failed,
        last_message: message
      )
    end

    def update_entity!(order_management_entity_ref)
      @entity.update_order_managament_ref_after_sync(order_management_entity_ref)
      Rails.logger.info(I18n.t('order_management.sync_success', entity_type: @entity.type, entity_id: @entity.id))

    end

    def find_entity(entity_id)
      OrderManagement::Entity.find(entity_id)
    end

    def start_processing_entity
      @entity.processing!
    end

    def last_sent_payload_changed_during_sync_process?
      @entity.last_request_payload != JSON.parse(@entity.payload_for_oms_csv.to_json)
    end

    def set_entity_as_synced
      return if last_sent_payload_changed_during_sync_process? || @entity.order_management_entity_ref.nil?

      @entity.update(sync_status: :in_sync, last_message: nil, last_result: :success)
      @entity.children.update_all(sync_status: 'out_of_sync') # rubocop:disable Rails/SkipsModelValidations
    end

    def reason_message
      "Cannot sync when state is #{context.entity.sync_status}"
    end
  end
end
