# frozen_string_literal: true

@product_attributes ||= product_attributes
@exclude_data ||= {}

cache_key = [
  I18n.locale,
  @current_user_roles.include?('admin'),
  current_pricing_options,
  @product_attributes,
  @exclude_data,
  @with_images,
  product,
  product.brand
]

json.cache! cache_key do # rubocop:disable Metrics/BlockLength
  if @migrated_to
    json.new_slug(@migrated_to.product.slug)
    json.option_type_name(@migrated_to.option_value.option_type.name)
    json.option_value_name(@migrated_to.option_value.name)
  elsif @real_product_slug.present?
    json.new_slug(@real_product_slug)
    json.option_type_name(nil)
    json.option_value_name(nil)
  end

  json.call(product, *@product_attributes)
  json.display_price Spree::Money.new(product.price || 0).to_s

  json.brand(product.brand&.name)
  json.brand_slug(product.brand&.permalink_part)
  json.brand_url(product.brand&.navigation_url)
  json.brand_description(product.brand_description)
  json.gift_card(product.gift_card)
  json.concierge_only(product.concierge_only?)
  json.is_registry(product.registry?)
  json.discontinued(product.discontinued?)
  json.available(product.available?)

  if @with_images
    json.images(product.gallery.images) do |image|
      json.mini_url image.attachment.url(:mini)
      json.small_url image.attachment.url(:small)
      json.product_url image.attachment.url(:product)
      json.large_url image.attachment.url(:large)
    end
  end

  json.maisonette_variant_group_attributes(product.maisonette_variant_group_attributes) do |variant_group_attributes|
    json.partial!(
      'maisonette/api/variant_group_attributes/variant_group_attributes',
      variant_group_attributes: variant_group_attributes
    )
  end

  unless @exclude_data[:taxons_for_display]
    json.trends(product.trends)
    json.breadcrumb_taxons do
      json.partial! 'spree/api/taxons/breadcrumb', collection: product.breadcrumb_taxons, as: :taxon
    end
  end

  unless @exclude_data[:variants]
    json.has_variants(product.has_variants?)
    json.master { json.partial!('spree/api/variants/small', variant: product.master) }
    json.variants(product.variants.with_option_values_on_non_master_variants) do |variant|
      json.partial!('spree/api/variants/big', variant: variant)
    end
  end

  unless @exclude_data[:option_types]
    json.option_types(product.option_types) { |option_type| json.call(option_type, *option_type_attributes) }
  end

  unless @exclude_data[:product_properties]
    json.product_properties(product.product_properties) do |product_property|
      json.call(product_property, *product_property_attributes)
    end
  end

  unless @exclude_data[:classifications]
    json.classifications(product.classifications) do |classification|
      json.call(classification, :taxon_id, :position)
      json.taxon { json.partial!('spree/api/taxons/taxon', taxon: classification.taxon, without_children: true) }
    end
  end

  if product.advertised_promotions.any?
    json.advertised_promotions(product.advertised_promotions) do |promotion|
      json.call(promotion, *promotion_attributes)
    end
  end
end
