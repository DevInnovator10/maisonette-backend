# frozen_string_literal: true

module OrderManagement
  class PriceBookEntry < OrderManagement::Entity
    def self.order_management_object_name
      'PricebookEntry'
    end

    def self.payload_presenter_class
      OrderManagement::PriceBookEntryPresenter
    end

    def self.parent_entity(target_object)
      OrderManagement::Product.find_by!(order_manageable: target_object.offer_settings)
    rescue ActiveRecord::RecordNotFound => e
      Sentry.capture_exception_with_message(e, message: 'Unable to find the parent entity')
      nil
    end
  end
end
