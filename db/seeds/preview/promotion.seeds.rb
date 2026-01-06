# frozen_string_literal: true

after 'preview:promotion_category' do
  I18n.t('seeds.promotions').each do |attrs|
    Spree::Promotion.find_or_initialize_by(name: attrs[:name]).tap do |promo|
      promo.attributes = attrs.slice(:description, :match_policy, :apply_automatically, :expires_at)

      rules = []
      promo.promotion_category = Spree::PromotionCategory.find_by!(code: attrs[:promotion_category])
      if attrs[:rules].present?
        promo.promotion_rules = attrs[:rules].map do |rule_attrs|
          rule_attrs[:class].constantize.new(rule_attrs.slice(:preferences)).tap do |rule|
            if rule_attrs[:shipping_methods].present?
              shipping_methods = rule_attrs[:shipping_methods].map do |shipping_method_code|
                Spree::ShippingMethod.find_by!(mirakl_shipping_method_code: shipping_method_code)
              end
              rules.push(promotion_rule: rule, shipping_methods: shipping_methods)
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

        action_record_attrs = action_attrs.slice(:preferences)
        if action_attrs.dig(:calculator)
          action_record_attrs = action_record_attrs.merge(calculator_attributes: action_attrs[:calculator].first)
        end
        action_attrs[:class].constantize.new(action_record_attrs)
      end

      notify_if_saved(promo)

      if promo.persisted?
        rules.each do |rule|
          rule[:shipping_methods]&.each do |shipping_method|
            shipping_method.promotion_rules << [rule[:promotion_rule]]
          end
        end
      end

      if promo.persisted? && attrs[:codes].present?
        if attrs[:name] == 'E-Gift Cards'
          attrs[:codes].each do |code|
            Maisonette::GiftCardGeneratorOrganizer.call!(
              promo_code: code,
              original_amount: 200,
              name: "Gift Card with code #{code}"
            ).gift_card
          end
        else
          attrs[:codes].each do |code|
            promo_code = Spree::PromotionCode.find_or_initialize_by(
              value: code,
              promotion: promo
            )
            notify_if_saved(promo_code)
          end
        end
      end
    end
  end
end
