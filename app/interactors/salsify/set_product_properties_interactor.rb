# frozen_string_literal: true

module Salsify
  class SetProductPropertiesInteractor < ApplicationInteractor
    def call
      set_properties
    end

    private

    def set_properties # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      Salsify::PRODUCT_PROPERTIES.each do |property_name|
        if context.row[property_name].blank?
          remove_properties(context.product, property_name)
        else
          set_property(context.product, property_name, context.row[property_name])
        end
      end

      Salsify::MULTI_VALUE_PRODUCT_PROPERTIES.each do |property_name|
        if context.row[property_name].blank?
          remove_properties(context.product, property_name)
        else
          set_multiple_value_property(context.product, property_name, context.row[property_name])
        end
      end
    end

    def remove_properties(product, property_name)
      property = Spree::Property.find_by(name: property_name)
      return unless property

      product_property = Spree::ProductProperty.where(
        product: product,
        property: property,
        maisonette_variant_group_attributes_id: context.variant_group_attributes&.id
      )
      return unless product_property.any?

      product_property.destroy_all
    end

    def set_property(product, property_name, value)
      property = Spree::Property.find_by!(name: property_name)
      product_property = Spree::ProductProperty.find_or_initialize_by(
        product: product,
        property: property,
        maisonette_variant_group_attributes_id: context.variant_group_attributes&.id
      )
      product_property.update(
        value: value.dup.force_encoding('UTF-8')
      )
    rescue ActiveRecord::RecordNotFound => e
      Sentry.capture_exception_with_message(e)
    end

    def set_multiple_value_property(product, property_name, values)
      property = Spree::Property.find_by!(name: property_name)

      destroy_product_properties(product, property)

      values.split(';').map(&:strip).each do |value|
        Spree::ProductProperty.create(
          product: product,
          property: property,
          value: value.dup.force_encoding('UTF-8'),
          maisonette_variant_group_attributes_id: context.variant_group_attributes&.id
        )
      end
    rescue ActiveRecord::RecordNotFound => e
      Sentry.capture_exception_with_message(e)
    end

    def destroy_product_properties(product, property)
      Spree::ProductProperty.where(
        product: product,
        property: property,
        maisonette_variant_group_attributes_id: context.variant_group_attributes&.id
      ).destroy_all
    end
  end
end
