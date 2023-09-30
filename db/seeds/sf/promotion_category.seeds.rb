# frozen_string_literal: true

I18n.t('seeds.promotion_categories').each do |attrs|
  Spree::PromotionCategory.find_by(name: 'Birthday promotion')&.update(name: 'Birthday Promotion')

  promotion_category = Spree::PromotionCategory.find_or_initialize_by(
    name: attrs[:name],
    code: attrs[:code]
  )

  promotion_category.gift_card = attrs[:gift_card]
  promotion_category.save

  notify(promotion_category, promotion_category.code)
end
