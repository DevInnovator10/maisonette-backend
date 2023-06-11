# frozen_string_literal: true

after 'taxonomy' do
  @taxon_color_burgundy = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_color, parent: @taxon_color, name: 'Burgundy'
  )
  notify @taxon_color_burgundy

  @taxon_color_brown = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_color, parent: @taxon_color, name: 'Brown'
  )
  notify @taxon_color_brown

  @taxon_color_metallic = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_color, parent: @taxon_color, name: 'Metallic'
  )
  notify @taxon_color_metallic

  @taxon_color_tan = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_color, parent: @taxon_color, name: 'Tan'
  )
  notify @taxon_color_tan

  @taxon_color_clear = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_color, parent: @taxon_color, name: 'Color-Clear'
  )
  notify @taxon_color_clear

  @taxon_color_cream = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_color, parent: @taxon_color, name: 'Cream'
  )
  notify @taxon_color_cream

  @taxon_color_gold = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_color, parent: @taxon_color, name: 'Gold'
  )
  notify @taxon_color_gold

  @taxon_color_neutral = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_color, parent: @taxon_color, name: 'Neutral'
  )
  notify @taxon_color_neutral

  @taxon_color_beige = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_color, parent: @taxon_color, name: 'Beige'
  )
  notify @taxon_color_beige

  @taxon_color_purple = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_color, parent: @taxon_color, name: 'Purple'
  )
  notify @taxon_color_purple
end
