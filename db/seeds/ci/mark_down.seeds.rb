# frozen_string_literal: true

after('ci:taxon_category_kids', 'ci:taxon_brand',
      'ci:product', 'ci:vendor', 'ci:taxon_trends') do
  vendor = Spree::Vendor.find_by!(name: "Luke's Toy Factory")

  product = Spree::Product.find_by!(name: 'EcoDump Truck')
  product.update!(taxons: [@taxon_category_kids, @taxon_trends_new_this_week])

  @mark_down_november = Spree::MarkDown.create(
    title: 'November Sale',
    amount: 0.15,
    vendor_liability: 50,
    our_liability: 50,
    included_taxons: [@taxon_category_kids]
  )
  notify @mark_down_november

  @mark_down_black_friday = Spree::MarkDown.create(
    title: 'Black Friday',
    amount: 0.20,
    vendor_liability: 50,
    our_liability: 50,
    included_taxons: [@taxon_category_kids],
    excluded_vendors: [vendor],
    active: true
  )
  notify @mark_down_black_friday
end
