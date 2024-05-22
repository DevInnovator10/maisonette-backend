# frozen_string_literal: true

module Spree::Taxon::Trends
  def self.prepended(base) # rubocop:disable Metrics/MethodLength
    base.const_set 'JUST_IN', 'Just In'
    base.const_set 'NEW_IN', 'New In'
    base.const_set 'NEW_TODAY', 'New Today'
    base.const_set 'NEW_THIS_WEEK', 'New This Week'
    base.const_set 'NEW_IN_SIX_WEEKS', 'New In Six Weeks'
    base.const_set 'SELLING_FAST', 'Selling Fast'
    base.const_set 'TRENDING_IN', 'Trending In'
    base.const_set 'SELLING_FAST_TODAY', 'Selling Fast Today'
    base.const_set 'SELLING_FAST_THIS_WEEK', 'Selling Fast This Week'
    base.const_set 'BEST_SELLERS_THIS_SEASON', 'Best Sellers This Season'
    base.const_set 'BEST_SELLERS', 'Best Sellers'
    base.const_set 'ALL_TIME_BEST_SELLERS', 'All Time Best Sellers'
    base.const_set 'MOST_WISHED', 'Most Wished'
    base.const_set 'ON_SALE', 'On Sale'
  end

  def repopulate(new_product_ids, new_product_with_vga_ids = nil)
    # we will be maintaining a separation on current code to prevent confusion on implementation
    process_products(new_product_ids)
    process_products_with_vga(new_product_with_vga_ids) if new_product_with_vga_ids.present?
  end

  private

  def process_products(new_product_ids)
    # explicitly process just the products WITHOUT vgas
    classifications.where(maisonette_variant_group_attributes_id: nil)
                   .where.not(product_id: new_product_ids).destroy_all
    new_product_ids -= classifications.where(maisonette_variant_group_attributes_id: nil).pluck(:product_id)
    new_product_ids.each do |product_id|
      Spree::Classification.create(product_id: product_id, taxon_id: id)
    end
  end

  def process_products_with_vga(new_product_with_vga_ids)
    # new_product_with_vga_ids format is [[<vga_id>, <product_id>]]
    classifications.where.not(product_id: new_product_with_vga_ids.map(&:last),
                              maisonette_variant_group_attributes_id: nil).destroy_all

    current_classifications = classifications.where.not(maisonette_variant_group_attributes_id: nil).pluck(:product_id)
    # remove from list if part of the current classifications
    new_product_with_vga_ids = new_product_with_vga_ids.map do |list|
      list if current_classifications.exclude?(list.last)
    end

    new_product_with_vga_ids.each do |mapping|
      Spree::Classification.create(maisonette_variant_group_attributes_id: mapping.first,
                                   product_id: mapping.last,

                                   taxon_id: id)
    end
  end
end
