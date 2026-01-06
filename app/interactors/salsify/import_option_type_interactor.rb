# frozen_string_literal: true

require 'with_advisory_lock'

module Salsify
  class ImportOptionTypeInteractor < ApplicationInteractor
    before :validate_context, :prepare_context

    def call
      context.option_values_hashes.each do |option_values_hash|
        option_type = context.option_types[option_values_hash[:type_name]] ||
                      ensure_product_option_exists_and_cleared(option_values_hash[:type_name])
        attrs = option_values_attributes(option_values_hash, option_type)
        option_value = Spree::OptionValue.create!(attrs)
      rescue ActiveRecord::RecordInvalid
        option_value = Spree::OptionValue.find_by!(attrs)
      ensure
        context.option_value_ids << option_value.id
      end
    end

    private

    def option_values_attributes(option_values_hash, option_type)
      { name: option_values_hash[:name], option_type_id: option_type.id, presentation: option_values_hash[:name] }
    end

    def validate_context
      context.fail!(messages: invalid_context_error) if context.variant.nil? || context.option_values_hashes.blank?
    end

    def invalid_context_error
      "Invalid context [#{__FILE__}:#{__LINE__}]"
    end

    def prepare_context
      context.option_types = {}
      context.option_value_ids = []
    end

    def ensure_product_option_exists_and_cleared(option_type_name)
      opt_type = nil
      result = Spree::OptionType.with_advisory_lock("find_or_create option #{option_type_name}", timeout_seconds: 15) do
        opt_type = Spree::OptionType.find_or_create_by!(name: option_type_name, presentation: option_type_name)
      end
      context.fail!(messages: "Can't acquire advisory lock [#{__FILE__}:#{__LINE__}]") if result == false
      Spree::ProductOptionType.find_or_create_by!(product_id: context.variant.product_id, option_type_id: opt_type.id)
      destroy_variant_option_values(opt_type)
      context.option_types[option_type_name] = opt_type
    end

    def destroy_variant_option_values(option_type)
      option_values = context.variant.option_values.where(option_type: option_type)

      return if option_values.blank?

      context.variant.option_values_variants.where(option_value_id: option_values).destroy_all
    end
  end
end
