# frozen_string_literal: true

after 'taxonomy' do
  @taxon_trends_new_today = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_trends,
    parent: @taxon_trends,
    name: 'New Today'
  )
  notify @taxon_trends_new_today

  @taxon_trends_new_this_week = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_trends,
    parent: @taxon_trends,
    name: 'New This Week'
  )
  notify @taxon_trends_new_this_week

  @taxon_trends_just_in = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_trends,
    parent: @taxon_trends,
    name: 'Just In'
  )
  notify @taxon_trends_just_in

  @taxon_trends_selling_fast = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_trends,
    parent: @taxon_trends,
    name: 'Selling Fast'
  )
  notify @taxon_trends_selling_fast
end
