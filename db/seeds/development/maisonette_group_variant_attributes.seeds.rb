# frozen_string_literal: true

after 'development:product_with_colors' do
  Spree::Product.joins(:option_types).where(spree_option_types: { name: 'Color' }).each do |product|
    color = product.option_types.find_by(name: 'Color')
    next unless color

    color.option_values.each do |ov|
      Maisonette::VariantGroupAttributes.find_or_create_by!(product_id: product.id, option_value_id: ov.id)
    end

    maisonette_variant_group_attributes = product.maisonette_variant_group_attributes.last
    # rubocop:disable Rails/SkipsModelValidations
    product.product_properties.update_all(
      maisonette_variant_group_attributes_id:
      maisonette_variant_group_attributes.id
    )
    # rubocop:enable Rails/SkipsModelValidations
  end
end
