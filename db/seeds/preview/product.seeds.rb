# frozen_string_literal: true

after 'preview:size_option',
      'preview:color_option',
      'preview:mirakl_shop' do
  default_shipping_category = Spree::ShippingCategory.find_by! name: 'Default'

  @offers = []
  @offer_settings = []
  I18n.t('seeds.products').each do |product_seed|
    name = product_seed[:name]
    product = Spree::Product.find_or_initialize_by(
      name: name,
      description: 'This is a test product description!',
      available_on: Time.zone.now,
      option_types: [Spree::OptionType.find_by(name: 'Size')]
    )

    product.master.shipping_category = default_shipping_category
    product.master.sku = product_seed[:parent_id]

    notify_if_saved(product, name)

    product_seed[:images]&.each do |image_path|
      product.images.create(attachment: File.open(image_path))
    end

    product.set_property('Box1 Packaged Weight', '1')
    product.set_property('Box1 Packaged Length', '3')
    product.set_property('Box1 Packaged Width/Depth', '4')
    product.set_property('Box1 Packaged Height', '5')

    I18n.t("seeds.variants.#{name.parameterize}").each do |variant_data|
      tax_category = Spree::TaxCategory.find_by(tax_code: variant_data[:tax_category_code])

      variant = product.variants.find_or_initialize_by(
        cost_price: variant_data[:offers][0][:price] * 0.75,
        tax_category: tax_category,
        sku: Digest::MD5.hexdigest(variant_data[:sku]),
        marketplace_sku: variant_data[:sku],
        shipping_category: default_shipping_category # TODO: international shipping
      )

      variant.save!

      variant_data[:offers].each do |offer_data|
        stock_location = Spree::StockLocation.find_by!(name: offer_data[:stock_location])
        offer_settings_data = offer_data[:offer_settings] || {}

        offer_setting = variant.offer_settings.find_or_initialize_by(vendor: stock_location.vendor) do |os|
          os.cost_price = offer_settings_data[:cost_price]
          os.monogrammable = offer_settings_data[:monogrammable] == true
          os.monogrammable_only = offer_settings_data[:monogrammable_only] == true
          os.monogram_price = offer_settings_data[:monogram_price]
          os.monogram_cost_price = offer_settings_data[:monogram_cost_price]
          os.monogram_lead_time = offer_settings_data[:monogram_lead_time]
          if offer_settings_data[:monogram_max_text_length].present?
            os.monogram_max_text_length = offer_settings_data[:monogram_max_text_length]
          end
          os.monogram_customizations = offer_settings_data[:monogram_customizations]
          os.vendor_sku = offer_data[:vendor_sku]
          os.maisonette_sku = offer_data[:maisonette_sku]
        end
        @offer_settings << offer_setting

        spree_price = variant.prices.find_or_initialize_by(amount: offer_data[:price],
                                                           vendor: stock_location.vendor,
                                                           currency: 'USD',
                                                           offer_settings: offer_setting)

        @offers << Mirakl::Offer.find_or_initialize_by(shop: stock_location.mirakl_shop,
                                                       price: offer_data[:price],
                                                       original_price: offer_data[:price],
                                                       offer_id: offer_data[:offer_id],
                                                       sku: offer_data[:maisonette_sku],
                                                       shop_sku: offer_data[:vendor_sku],
                                                       quantity: 50,
                                                       active: true,
                                                       spree_price: spree_price)

        stock_item = variant.stock_items.find_or_initialize_by(
          stock_location: stock_location
        )

        stock_item.set_count_on_hand(999)
      end
      notify_if_saved(variant, variant.sku)
      variant.option_values << Spree::OptionValue.find_by!(name: variant_data[:size])
    end

    @offer_settings.each(&:save!)
    @offers.each(&:save!)
  end
end
