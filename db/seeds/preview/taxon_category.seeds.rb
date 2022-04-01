# frozen_string_literal: true

after 'taxonomy' do
  @taxon_category_gear = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category,
    name: 'Gear'
  )
  notify @taxon_category_gear

  @taxon_category_sale = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category,
    name: 'Sale'
  )
  notify @taxon_category_sale

  @taxon_category_sale_shop = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_sale,
    name: 'Shop Sale'
  )
  notify @taxon_category_sale_shop

  @taxon_category_sale_shop = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_sale,
    name: 'New in Sale'
  )
  notify @taxon_category_sale_shop
end
