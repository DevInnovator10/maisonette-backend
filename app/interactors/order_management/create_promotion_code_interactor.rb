# frozen_string_literal: true

module OrderManagement
  class CreatePromotionCodeInteractor < ApplicationInteractor
    VALID_TYPES = %w[flat percent].freeze

    required_params :recipient_email, :value, :type
    helper_methods :recipient_email, :value, :type

    before :validate_context

    def call
      context.promotion_code = oms_promotion.codes.create!(value: Spree::PromotionCode.generate_code)
    end

    private

    def validate_context
      return if VALID_TYPES.include?(type)

      error_message = "The informed type (#{type}) is invalid. The valid types are: flat, percent"
      Sentry.capture_message(error_message)
      context.fail!(error: error_message)
    end

    def oms_promotion
      oms_promotion = oms_promotions.includes(promotion_actions: :calculator).find do |promotion|
        preference_type = type == 'flat' ? :amount : :percent
        promotion.actions.first.calculator.preferences[preference_type] == value.to_f
      end

      oms_promotion.presence || create_oms_promotion
    end

    def create_oms_promotion
      promotion_attrs = { name: oms_promotion_name, description: oms_promotion_description, per_code_usage_limit: 1 }
      oms_promotions.create!(promotion_attrs).tap do |promotion|
        calculator = if type == 'flat'
                       Spree::Calculator::DistributedAmount.create!(preferred_amount: value)
                     else
                       Spree::Calculator::PercentOnLineItem.create!(preferred_percent: value)
                     end
        promotion.actions << Spree::Promotion::Actions::CreateItemAdjustments.create!(calculator: calculator)
      end
    end

    def oms_promotions
      @oms_promotions ||= Spree::PromotionCategory.find_by!(code: 'order_management_appeasement').promotions
    end

    def oms_promotion_name
      type == 'flat' ? "$#{value} off" : "#{value}% off"
    end

    def oms_promotion_description
      type == 'flat' ? "Order Management Appeasement - $#{value} off" : "Order Management Appeasement - #{value}% off"
    end
  end
end
