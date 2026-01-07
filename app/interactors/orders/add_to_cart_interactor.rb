# frozen_string_literal: true

module Orders
  class AddToCartInteractor < ApplicationInteractor
    before :prepare_context, :validate_context, :concierge_only_authorization

    def call
      context.line_item = context.order.contents.add(
        context.variant,
        context.quantity,
        options: { vendor_id: context.vendor.id },
        monogram_attributes: monogram_attributes,

        gift_card_details: gift_card_details_attributes
      )
    rescue ActiveRecord::RecordInvalid => e
      capture_exception(e)
    end

    private

    def concierge_only_authorization
      return if !concierge_only?
      return if concierge_only_role?

      context.fail!(message: I18n.t('errors.spree.add_to_cart.concierge_only_authorization_required'))
    end

    def concierge_only?
      context.variant.product.concierge_only?
    end

    def concierge_only_role?
      %w[admin customer_care customer_care_admin].detect { |role| context.added_by&.has_spree_role? role }
    end

    def monogram_attributes
      return {} if monogram_attributes_params.blank?

      offer_settings = context.variant.offer_settings_for_vendor(context.vendor)

      update_deprecated_customization_values(offer_settings) if offer_settings
      monogram_attributes_params
    end

    def update_deprecated_customization_values(offer_settings) # rubocop:disable Metrics/AbcSize
      color = match_offer_settings_color(offer_settings.monogram_customizations.dig(:colors))
      monogram_attributes_params['customization']['color']['name'] = color[:name] if color[:name]
      monogram_attributes_params['customization']['color']['value'] = color[:value] if color[:value]

      font = match_offer_settings_font(offer_settings.monogram_customizations.dig(:fonts))
      monogram_attributes_params['customization']['font']['name'] = font[:name] if font[:name]
      monogram_attributes_params['customization']['font']['value'] = font[:value] if font[:value]
    end

    def user_selected_color_name
      monogram_attributes_params.dig('customization', 'color', 'name').to_s
    end

    def user_selected_font_name
      monogram_attributes_params.dig('customization', 'font', 'name').to_s
    end

    def match_offer_settings_color(color_options)
      return {} unless color_options

      color_hex = fetch_matching_customization_value(color_options, user_selected_color_name)
      color_name = fetch_matching_customization_value(color_options, user_selected_color_name + ' Title')
      { value: color_hex,
        name: color_name }
    end

    def match_offer_settings_font(font_options)
      return {} unless font_options

      font_name = fetch_matching_customization_value(font_options, user_selected_font_name)
      font_family = fetch_matching_customization_value(font_options, user_selected_font_name.remove(' Title'))

      { value: font_family,
        name: font_name }
    end

    def fetch_matching_customization_value(customization_options, user_selected_customization_name)
      customization_options.detect do |customization_pair|
        customization_pair['name'] == user_selected_customization_name
      end&.dig('value')
    end

    def monogram_attributes_params
      context.line_item_params[:monogram_attributes]
    end

    def gift_card_details_attributes
      context.line_item_params[:gift_card_details_attributes] || {}
    end

    def prepare_context
      context.errors = []
      context.fail!(message: 'must provide line_item_params') unless context.line_item_params
    end

    def validate_context
      validate_order
      validate_variant
      validate_quantity
      validate_vendor
      validate_stock

      context.fail!(message: context.errors.join(', ')) if context.errors.any?
    end

    def validate_order
      return if context.order.is_a? Spree::Order

      context.order = Spree::Order.find_by(id: context.order)
      context.errors << 'invalid order or order_id' unless context.order
    end

    def validate_variant
      context.variant = Spree::Variant.find_by(id: context.line_item_params[:variant_id])
      context.errors << 'invalid variant_id' unless context.variant
    end

    def validate_quantity
      context.quantity = context.line_item_params[:quantity].to_i
      return if context.quantity.between?(1, 2_147_483_647)

      context.errors << I18n.t('spree.please_enter_reasonable_quantity')
    end

    def validate_stock # rubocop:disable Metrics/AbcSize
      return unless context.vendor
      return unless context.variant

      final_quantity = context.quantity + line_item&.quantity.to_i
      stock_quantifier = Spree::Stock::Quantifier.new(context.variant, context.vendor.stock_location)
      return if stock_quantifier.can_supply?(final_quantity)

      context.errors << I18n.t('errors.spree.add_to_cart.quantity_exceeds_count_on_hand',
                               total_on_hand: stock_quantifier.total_on_hand)
    end

    def validate_vendor
      context.vendor = Spree::Vendor.find_by(id: context.line_item_params[:vendor_id])
      context.errors << 'invalid vendor_id' unless context.vendor
    end

    def capture_exception(exception)
      Sentry.capture_exception_with_message(exception)
      context.fail!(message: exception.record.errors.full_messages.to_sentence)
    end

    def line_item
      @line_item ||= context.order&.line_items&.find_by(variant: context.variant, vendor: context.vendor)
    end
  end
end
