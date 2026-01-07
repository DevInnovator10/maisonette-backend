# frozen_string_literal: true

module Syndication
  class KlaviyoExportWorker
    include Sidekiq::Worker

    def perform
      S3.put(
        klaviyo_syndication_filepath,
        json_payload,
        bucket: syndication_bucket,
        region: syndication_region,
        acl: 'public-read'
      )
    end

    private

    def json_payload
      Syndication::Product.where(is_product: true).map(&method(:klaviyo_product)).to_json
    end

    def klaviyo_product(product)
      {
        '$id' => product.maisonette_sku,
        '$price' => product.price_min || 0,
        '$title' => product.product_name,
        '$link' => product.product_url,
        '$image_link' => product.image,
        '$description' => product.vendor_sku_description,
        'brand' => product.brand,
        'total_on_hand' => product.inventory,
        'categories' => combined_categories(product)
      }
    end

    def combined_categories(product)
      product.gender.to_a.map { |gender| "Gender: #{gender}" } |
        product.age_range.to_a.map { |age_range| "Age Range: #{age_range}" } |
        product.category.to_a.map { |category| "Category: #{category}" } |
        product.product_type.to_a.map { |product_type| "Product Type: #{product_type}" } |
        product.trends.to_a.map { |trend| "Trend: #{trend}" }
    end

    def klaviyo_syndication_filepath
      'klaviyo/products.json'
    end

    def syndication_bucket
      Maisonette::Config.fetch('aws.syndication_bucket')
    end

    def syndication_region
      Maisonette::Config.fetch('aws.region')
    end
  end
end
