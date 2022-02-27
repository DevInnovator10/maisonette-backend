# frozen_string_literal: true

module Salsify
  class Exception < StandardError
    attr_accessor :resource_class, :resource_id

    def initialize(msg, resource_class: nil, resource_id: nil)
      raise(ArgumentError) if (resource_class.blank? && resource_id.present?) ||
                              (resource_class.present? && resource_id.blank?)

      super(msg)
      self.resource_class = resource_class
      self.resource_id = resource_id
    end

    def resource
      resource_class.find(resource_id) if resource_class && resource_id
    end
  end
end
