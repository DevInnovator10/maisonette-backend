# frozen_string_literal: true

after 'taxonomy' do
  @taxon_category_baby = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category,
    name: 'Baby'
  )
  notify @taxon_category_baby

  @taxon_category_baby_trending = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_baby,
    name: 'Trending in Baby'
  )
  notify @taxon_category_baby_trending

  @taxon_category_baby_boy = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_baby,
    name: 'Boy Clothing'
  )
  notify @taxon_category_baby_boy

  @taxon_category_baby_boy_pants = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_baby_boy,
    name: 'Pants'
  )
  notify @taxon_category_baby_boy_pants

  @taxon_category_baby_boy_tops = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_baby_boy,
    name: 'Tops'
  )
  notify @taxon_category_baby_boy_tops

  @taxon_category_baby_girl = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_baby,
    name: 'Girl Clothing'
  )
  notify @taxon_category_baby_girl

  @taxon_category_baby_girl_skirts = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_baby_girl,
    name: 'Skirts'
  )
  notify @taxon_category_baby_girl_skirts

  @taxon_category_baby_girl_tops = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_baby_girl,
    name: 'Tops'
  )
  notify @taxon_category_baby_girl_tops
end
