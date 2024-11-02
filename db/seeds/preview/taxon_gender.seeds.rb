# frozen_string_literal: true

after 'taxonomy' do
  @taxon_gender_boy = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_gender,
    parent: @taxon_gender,
    name: 'Boy'
  )
  notify @taxon_gender_boy

  @taxon_gender_girl = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_gender,
    parent: @taxon_gender,
    name: 'Girl'
  )
  notify @taxon_gender_girl

  @taxon_gender_babyboy = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_gender,
    parent: @taxon_gender,
    name: 'Baby Boy'
  )
  notify @taxon_gender_babyboy

  @taxon_gender_babygirl = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_gender,
    parent: @taxon_gender,
    name: 'Baby Girl'
  )
  notify @taxon_gender_babygirl

  @taxon_gender_babyunisex = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_gender,
    parent: @taxon_gender,
    name: 'Baby Unisex'
  )
  notify @taxon_gender_babyunisex

  @taxon_gender_unisex = Spree::Taxon.find_or_create_by(
    taxonomy: @taxonomy_gender,
    parent: @taxon_gender,
    name: 'Unisex'
  )
  notify @taxon_gender_unisex
end
