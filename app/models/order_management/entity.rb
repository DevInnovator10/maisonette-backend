# frozen_string_literal: true

module OrderManagement
  class Entity < ApplicationRecord
    belongs_to :order_manageable, -> { try(:with_discarded) }, polymorphic: true
    belongs_to :parent, foreign_key: :parent_id,
                        class_name: 'OrderManagement::Entity', inverse_of: :children, optional: true
    has_many :children, foreign_key: :parent_id,
                        class_name: 'OrderManagement::Entity', inverse_of: :parent,
                        dependent: :nullify

    enum sync_status: {
      out_of_sync: 1,
      processing: 2,
      in_sync: 3,
      waiting_parent_forward: 4
    }

    enum last_result: {
      success: 1,
      failed: 2
    }

    def self.sync_enabled?
      Flipper.enabled?(:oms_sync) && Flipper.enabled?("oms_sync_#{name.underscore}")
    end

    def self.advisory_lock_key(target_object)
      "handle_record_sync_status #{name} #{target_object.class.name}##{target_object.id}"
    end

    def self.advisory_lock(target_object)
      with_advisory_lock(advisory_lock_key(target_object)) do
        yield
      end
    end

    def self.mark_out_of_sync!(target_object)
      return unless target_object.persisted?

      advisory_lock(target_object) do
        parent = parent_entity(target_object)
        if parent.nil? || parent.forwarded?
          set_sync_status(target_object, parent, :out_of_sync)
        else
          set_sync_status(target_object, parent, :waiting_parent_forward)
        end
      end
    end

    def perform_remote_upsert!
      return unless self.class.sync_enabled?

      OrderManagement::ClientInterface.upsert!(
        self.class.order_management_object_name, 'External_ID__c',
        payload.merge("External_ID__c": external_id)
      )
    end

    def sync_order_management!
      return if unsyncable_statuses.include? sync_status
      return if parent && !parent.forwarded?

      OrderManagement::SyncEntityWorker.perform_async(id)
    end

    def payload
      self.class.payload_presenter_class.new(order_manageable).payload.with_indifferent_access
    end

    def payload_for_oms_csv
      generated_payload = respond_to?(:historical_oms_payload) ? historical_oms_payload : payload
      generated_payload.with_indifferent_access
    end

    def external_id
      to_gid_param
    end

    def self.order_management_object_name
      raise 'Define the order management object name'
    end

    def self.payload_presenter_class
      raise 'Presenter class is not defined'
    end

    def self.parent_entity(_target_object)
      nil
    end

    def forwarded?
      order_management_entity_ref.present?
    end

    def update_order_managament_ref_after_sync(order_management_entity_ref)
      update!(
        sync_status: :in_sync,
        last_result: :success,
        last_request_payload: reload.payload_for_oms_csv,
        last_message: nil,
        order_management_entity_ref: order_management_entity_ref
      )
      children.update_all(sync_status: 'out_of_sync') # rubocop:disable Rails/SkipsModelValidations
    end

    class << self
      def set_sync_status(target_object, parent, sync_status)
        order_management_entity = find_or_initialize_by(
          order_manageable_type: target_object.class.name,
          order_manageable_id: target_object.id,
          parent_id: parent&.id
        )
        order_management_entity.sync_status = sync_status
        order_management_entity.save!
      end
    end

    private

    def unsyncable_statuses
      %w[processing waiting_parent_forward]
    end
  end
end
