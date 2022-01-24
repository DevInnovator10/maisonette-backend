# frozen_string_literal: true

after 'taxonomy' do
  @taxon_category_kids = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category,
    name: 'Kids'
  )
  notify @taxon_category_kids

  @taxon_category_kids_girl = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_kids,
    name: 'Girl Clothing'
  )
  notify @taxon_category_kids_girl

  @taxon_category_kids_boy = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_kids,
    name: 'Boy Clothing'
  )
  notify @taxon_category_kids_boy

  @taxon_category_kids_news = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_kids,
    name: 'New in Kids'
  )
  notify @taxon_category_kids_news

  @taxon_category_kids_trending = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_category,
    parent: @taxon_category_kids,
    name: 'Trending in Kids'
  )
  notify @taxon_category_kids_trending
end
