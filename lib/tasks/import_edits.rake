# frozen_string_literal: true

namespace :lpc do # rubocop:disable Metrics/BlockLength
  desc 'Import Edits from LPCs'
  task import_edits: [:environment] do # rubocop:disable Metrics/BlockLength
    edits_feed_file = ENV['EDITS_FEED_FILE']
    csv_file = S3.get("lpc-to-edits/#{edits_feed_file}", bucket: Maisonette::Config.fetch('aws.bucket'))
    edits_rows = CSV.parse(csv_file, headers: true, col_sep: ',')

    edit_taxon = Spree::Taxon.find_by!(name: 'Edits')

    classifications_attributes = []
    insert_time = Time.zone.now
    edits_rows.each do |row|
      product = Spree::Variant.find_by(sku: row['ID'], is_master: true)&.product
      Spree::LogEntry.create(source_id: 'lpcs-to-edits', details: row.to_json) && next unless product

      # Taxon has been created when running https://github.com/MaisonetteWorld/maisonette-backend/blob/develop/lib/tasks/sli.rake#L172
      row['Edits'].split("\;").map(&:strip).each do |taxon_name|
        taxon = Spree::Taxon.find_by(parent: edit_taxon, name: taxon_name)

        Spree::LogEntry.create(source_id: 'lpcs-to-edits', details: taxon_name) && next unless taxon

        # do nothing if product already has this edits.
        next if Spree::Classification.find_by(product_id: product.id, taxon_id: taxon.id)

        classifications_attributes << {
          product_id: product.id,
          taxon_id: taxon.id,
          created_at: insert_time,
          updated_at: insert_time
        }
      end
    rescue StandardError => _e
      Spree::LogEntry.create(source_id: 'lpcs-to-edits', details: row.to_json)
    end
    puts "Going to insert #{classifications_attributes.count} classifications"
    Spree::Classification.insert_all(classifications_attributes)
    puts 'Done!'
  end
end
