# frozen_string_literal: true

after 'preview:stock_location' do
    gift_card = I18n.t('seeds.gift_card')
  name = gift_card[:name]

  gift_card_option_type = Spree::OptionType.find_or_create_by!(name: 'Amount', presentation: 'Amount')

  product = Spree::Product.find_or_initialize_by(
    name: name,
    description: FFaker::Lorem.sentence,
    available_on: Time.zone.now,
    option_types: [gift_card_option_type],
    gift_card: true,
    promotionable: false,
    concierge_only: true
  )

  master_price = I18n.t("seeds.gift_cards_variants.#{name.parameterize}")[0][:price]
  product.master.shipping_category = Spree::ShippingCategory.find_by(name: 'Digital')
  product.master.sku = gift_card[:parent_id]

  notify_if_saved(product, name)

  I18n.t("seeds.gift_cards_variants.#{name.parameterize}").each do |variant_data|
    shipping_category = Spree::ShippingCategory.find_by(name: 'Digital')
    stock_location = Spree::StockLocation.find_by!(name: variant_data[:stock_location])

    variant = product.variants.find_or_initialize_by(
      cost_price: master_price * 0.75,
      sku: Digest::MD5.hexdigest(variant_data[:sku]),
      marketplace_sku: variant_data[:sku],
      shipping_category: shipping_category
    )

    variant.prices.build(vendor: Spree::Vendor.default, amount: variant_data[:price])

    variant.option_values << Spree::OptionValue.find_or_create_by!(name: "$#{variant_data[:price]}",
                                                                   option_type: gift_card_option_type,
                                                                   presentation: "$#{variant_data[:price]}")
    stock_item = variant.stock_items.find_or_initialize_by(
      stock_location: stock_location
    )
    stock_item.set_count_on_hand(1000)
    notify_if_saved(variant, variant.sku)

    variant.offer_settings.find_or_create_by!(vendor: stock_location.vendor) do |offer_setting|
      offer_setting.maisonette_sku = variant_data[:maisonette_sku]
      offer_setting.vendor_sku = variant_data[:vendor_sku]
      offer_setting.final_sale = true
    end
  end
end
