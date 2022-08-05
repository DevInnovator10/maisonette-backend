# frozen_string_literal: true

namespace :utils do # rubocop:disable Metrics/BlockLength
  task salsify_import_reset: :environment do
    return if Rails.env.production? || Rails.env.ppd? || Rails.env.sf

    Salsify::Import.delete_all
    Salsify::ImportRow.delete_all
  end

  task :salsify_import_products, [:csv_path] => [:environment] do |_t, args|
    csv_path = args[:csv_path].to_s
    (puts("! Invalid Salsify CSV file path: #{csv_path}") & exit) unless File.file?(csv_path)
    Salsify::ProductsImportInteractor.call(local_files: [csv_path], delete_local_file: false)
  end

  task :salsify_import_brands, [:csv_path] => [:environment] do |_t, args|
    csv_path = args[:csv_path].to_s
    (puts("! Invalid Salsify CSV file path: #{csv_path}") & exit) unless File.file?(csv_path)
    Salsify::BrandsImportInteractor.call(local_files: [csv_path], delete_local_file: false)
  end

  task :reprocess_variant_without_hashed_sku, [:import_id] => [:environment] do |_t, args| # rubocop:disable Metrics/LineLength, Metrics/BlockLength
    import_rows = Salsify::ImportRow.where(
      salsify_import_id: args[:import_id],
      messages: 'Validation failed: Maisonette sku has already been taken'
    )
    puts "Found #{import_rows.count} import rows to fix"

    import_rows.find_each do |import_row|
      json_data = import_row.data

      maisonette_sku = json_data['Maisonette SKU']
      marketplace_sku = json_data['Marketplace SKU']
      hashed_sku = Digest::MD5.hexdigest(marketplace_sku)

      placeholder_variant = Spree::Variant.with_discarded.find_by(sku: maisonette_sku, marketplace_sku: nil)
      next if placeholder_variant.nil?

      salsify_variant = Spree::Variant.with_discarded.find_by(sku: hashed_sku)

      if salsify_variant.present?
        next if salsify_variant.product_id != placeholder_variant.product_id

        Spree::OfferSettings.with_discarded
                            .where(variant_id: placeholder_variant.id)
                            .update_all(variant_id: salsify_variant.id) # rubocop:disable Rails/SkipsModelValidations

        placeholder_variant.delete
      else
        placeholder_variant.update_column(:sku, hashed_sku) # rubocop:disable Rails/SkipsModelValidations
        placeholder_variant
          .update_column(:marketplace_sku, marketplace_sku) # rubocop:disable Rails/SkipsModelValidations
      end

      puts "\"#{maisonette_sku}\" => \"#{marketplace_sku}\","
    end
  end
end
