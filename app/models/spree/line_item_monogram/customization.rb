# frozen_string_literal: true

module Spree
  class LineItemMonogram < ApplicationRecord
    class Customization < HashWithIndifferentAccess
      extend ActiveModel::Naming
      extend ActiveModel::Translation

      CUSTOMIZATION_TYPES = OfferSettings::MonogramCustomizations::CUSTOMIZATIONS_TYPES.map(&:singularize).freeze

      attr_reader :errors
      attr_accessor :record

      def initialize(hash)
        super hash

        @errors = ActiveModel::Errors.new self
      end

      def valid?
        validate! if errors.blank?

        errors.blank?
      end

      def invalid?
        !valid?
      end

      private

      def validate!
        if (keys - CUSTOMIZATION_TYPES).present?
          return errors.add :base, :any_invalid_customization_type
        end

        if missing_required_types.any?
          return errors.add :base, :any_missing_customization_type, types: missing_required_types.join(', ')
        end

        each { |customization_type, customization| validate_customization! customization_type, customization }
      end

      def missing_required_types
        record.available_customizations.keys.map(&:singularize) - keys
      end

      def available_customizations_for_type(customization_type)
        record.available_customizations[customization_type.pluralize] || []
      end

      def validate_customization!(customization_type, customization)
        available_customizations = available_customizations_for_type customization_type

        name = validate_name(available_customizations, customization)
        value = validate_value(available_customizations, customization)

        return if name && value

        errors.add :base,
                   :available_customizations_inclusion,
                   customization_type: customization_type,
                   customization: customization,
                   available_customizations: available_customizations
      end

      def validate_name(available_customizations, customization)
        available_customizations.detect do |available_customization|
          available_customization['value'] == customization['name']
        end
      end

      def validate_value(available_customizations, customization)
        available_customizations.detect do |available_customization|
          available_customization['value'] == customization['value']
        end
      end
    end
  end
end
