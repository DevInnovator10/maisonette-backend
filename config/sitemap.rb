# frozen_string_literal: true

SitemapGenerator::Sitemap.default_host = Maisonette::Config.fetch('base_url').to_s
SitemapGenerator::Interpreter.include UrlHelper
SitemapGenerator::Sitemap.adapter = SitemapGenerator::AwsSdkAdapter.new(
  Maisonette::Config.fetch('aws.bucket'),
  aws_access_key_id: Maisonette::Config.fetch('aws.access_key_id'),
  aws_secret_access_key: Maisonette::Config.fetch('aws.secret_access_key'),
  aws_region: Maisonette::Config.fetch('aws.region')
)

SitemapGenerator::Sitemap.create do # rubocop:disable Metrics/BlockLength
  default_options = { changefreq: 'daily' }
  urls_to_add = {}

  urls_to_add['account'] = {}
  urls_to_add['checkout/registration'] = {}
  urls_to_add['password/recover'] = {}
  urls_to_add['password/reset'] = {}
  urls_to_add['login'] = {}
  urls_to_add['signup'] = {}
  urls_to_add['size-guide'] = {}

  Spree::Product.available.pluck(:slug, :updated_at).each do |(slug, updated_at)|
    urls_to_add[product_path_from_slug(slug)] = default_options.merge(lastmod: updated_at)
  end

  # Brands
  brand_taxons = Spree::Taxon.purchasable_brands
  brand_taxons.visible.find_each do |taxon|
    urls_to_add[taxon.navigation_url] = default_options.merge(lastmod: taxon.updated_at)
  end

  # Trends
  trends_taxons = Spree::Taxon.purchasable_trends
  trends_taxons.visible.find_each do |taxon|
    urls_to_add[taxon.navigation_url] = default_options.merge(lastmod: taxon.updated_at)
  end

  # Navigation
  navigation_taxons = Spree::Taxon.navigation_taxons
  navigation_taxons.visible.find_each do |taxon|
    # remove tracking query params td=
    taxon_url = taxon.navigation_url.remove(/\s?td=\S+\s?/).delete_suffix('?')
    urls_to_add[taxon_url] = default_options.merge(lastmod: taxon.updated_at)
  end

  # CMS Pages
  cms_pages = JSON.parse(RestClient.get(Maisonette::Config.fetch('sitemap.cms_pages_endpoint')).body)
  cms_pages.each do |page|
    urls_to_add[page['URL']] = default_options.merge(lastmod: page['updated_at'])
  end

  # Edits
  context = ::Sitemap::ExtractEditsInteractor.call
  if context.success? && context.edits
    context.edits.each do |taxon|
      urls_to_add[taxon.navigation_url] = default_options.merge(lastmod: taxon.updated_at)
    end
  end

  # Careers
  urls_to_add['/careers'] = {}
  begin
    careers_url = Maisonette::Config.fetch('greenhouse.careers_url')
    if careers_url
      JSON.parse(RestClient.get(careers_url))['jobs'].each do |job|
        job_path = job['title'].gsub(/\W/, '').downcase
        urls_to_add["/careers/#{job_path}"] = default_options.merge(lastmod: job['updated_at'])
      end
    end
  rescue StandardError => e
    Sentry.capture_exception_with_message(e, message: 'Issue adding careers URLs to sitemap')
  end

  # Algolia Facets
  context = ::Sitemap::AlgoliaFacetsInteractor.call
  if context.success? && context.facet_urls
    context.facet_urls.each do |facet_url|
      urls_to_add[facet_url] = default_options
    end
  end

  # remove urls that have app-index keyword
  urls_to_add.reject! { |url, _options| url.to_s.include?('app-index') }

  urls_to_add.each { |url, options| add(url, options) }
end
