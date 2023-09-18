# frozen_string_literal: true

after 'ppd:promotion_category' do
  ActiveRecord::Base.connection.set_pk_sequence!(
    Spree::Promotion.table_name, [100_000, Spree::Promotion.maximum(:id).to_i].max
  )
  ActiveRecord::Base.connection.set_pk_sequence!(
    Spree::PromotionAction.table_name, [100_000, Spree::Promotion.maximum(:id).to_i].max
  )
  ActiveRecord::Base.connection.set_pk_sequence!(
    Spree::PromotionRule.table_name, [100_000, Spree::Promotion.maximum(:id).to_i].max
  )

  I18n.t('seeds.promotions').each do |attrs|
    promo = Spree::Promotion.find_or_initialize_by(name: attrs[:name])
    next unless promo.new_record?

    promo.attributes = attrs.slice(:description, :match_policy, :apply_automatically, :per_code_usage_limit)

    promo.promotion_category = Spree::PromotionCategory.find_by!(code: attrs[:promotion_category])
    if attrs[:rules].present?
      promo.promotion_rules = attrs[:rules].map do |rule_attrs|
        rule_attrs[:class].constantize.new(rule_attrs.slice(:preferences)).tap do |rule|
          if rule_attrs[:shipping_methods].present?
            rule.shipping_methods = rule_attrs[:shipping_methods].map do |shipping_method_code|
              Spree::ShippingMethod.find_by!(mirakl_shipping_method_code: shipping_method_code)
            end
          end
        end
      end
    end

    promo.promotion_actions = attrs[:actions].map do |action_attrs|
      if action_attrs.dig(:preferences, :shipping_method).present?
        action_attrs[:preferences][:shipping_method_id] =
          Spree::ShippingMethod.find_by!(mirakl_shipping_method_code: action_attrs[:preferences][:shipping_method]).id

        action_attrs[:preferences].extract!(:shipping_method)
      end

      attrs = action_attrs.slice(:preferences)
      attrs = attrs.merge(calculator_attributes: action_attrs[:calculator].first) if action_attrs.dig(:calculator)
      action_attrs[:class].constantize.new(attrs)
    end

    notify_if_saved(promo)
  end
end
