# frozen_string_literal: true

after 'taxonomy' do
    @taxon_brand_lola = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_brand,
    parent: @taxon_brand,
    name: 'Lola + The Boys'
  )

  notify @taxon_brand_lola

  @taxon_brand_loopdedoo = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_brand,
    parent: @taxon_brand,
    name: 'Loopdedoo'
  )
  notify @taxon_brand_loopdedoo

  @taxon_brand_isabel = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_brand,
    parent: @taxon_brand,
    name: 'Isabel Garreton'
  )
  notify @taxon_brand_isabel

  @taxon_brand_primary = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_brand,
    parent: @taxon_brand,
    name: 'Primary x Maisonette'
  )
  notify @taxon_brand_primary

  @taxon_brand_storksak = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_brand,
    parent: @taxon_brand,
    name: 'Storksak'
  )
  notify @taxon_brand_storksak

  @taxon_brand_schoenhut = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_brand,
    parent: @taxon_brand,
    name: 'Schoenhut'
  )
  notify @taxon_brand_schoenhut

  @taxon_brand_piccoli = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_brand,
    parent: @taxon_brand,
    name: 'Piccoli Principi'
  )
  notify @taxon_brand_piccoli

  @taxon_brand_rodini = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_brand,
    parent: @taxon_brand,
    name: 'Mini Rodini'
  )
  notify @taxon_brand_rodini
end
