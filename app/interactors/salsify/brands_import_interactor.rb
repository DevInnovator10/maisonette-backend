# frozen_string_literal: true

module Salsify
  class BrandsImportInteractor < ApplicationInteractor
    MATCHER = '*brand_setup*.csv'
    SOURCE_PATH = '/Spree/CSV'
    BACKUP_PATH = '/Spree/CSV/backup'

    def call
      @local_path = Maisonette::Config.fetch('salsify.local_path')
      fetch
      parse
      import
    end

    private

    def check_csv_headers(csv_data)
      return Salsify.salsify_error(:no_headers) if csv_data.headers.blank?
      return Salsify.salsify_error(:nil_header) unless csv_data.headers.exclude?(nil)
    end

    def fetch
      if !context.local_files
        ftp = Salsify::FTP.new(matcher: MATCHER, source_path: SOURCE_PATH, backup_path: BACKUP_PATH)

        ftp.fetch(local_path: @local_path) do |file|
          create_file_import(file)
        end
      else
        context.local_files.each do |file|
          create_file_import(file)
        end
      end
    end

    def create_file_import(file)
      @brand_imports ||= []
      @brand_imports << Salsify::Import.create!(file_to_import: file, state: :created, import_type: :brands)
    end

    def import
      brand_taxonomy = Spree::Taxonomy.find_by name: 'Brand'
      brand_taxon = Spree::Taxon.find_by name: 'Brand'
      Salsify::Import.by_type(:brands).imported.each do |import|
        import.processing!
        import.salsify_import_rows.created.each do |row|
          Salsify::ImportBrandInteractor.call row: row, brand_taxonomy: brand_taxonomy, brand_taxon: brand_taxon
        end
        import.completed!
        import.import_file.unlink if import.import_file.exist?
      end
    end

    def parse
      @brand_imports&.each do |import|
        path = Pathname.new(@local_path).join(import.file_to_import)
        csv_data = Salsify.parse_csv_file(path)
        errors = check_csv_headers(csv_data)
        next prepare_rows(import, csv_data) unless errors

        import.update(messages: errors, state: :failed)
        Sentry.capture_exception_with_message Salsify::Exception.new(errors,
                                                                     resource_class: Salsify::Import,
                                                                     resource_id: import.id)
      ensure
        File.delete(path) if File.exist?(path)
      end
    end

    def prepare_rows(import, csv_data) # rubocop:disable Metrics/MethodLength
      import.salsify_import_rows.destroy_all
      errors = []
      csv_data.each do |row|
        row_context = Salsify::PrepareRowInteractor.call(import: import, row: row)
        errors << row_context.error if row_context.failure?
      end
      if errors.any?
        import.update(messages: errors.join(', '), state: :failed)
        Sentry.capture_exception_with_message Salsify::Exception.new(errors,
                                                                     resource_class: Salsify::Import,
                                                                     resource_id: import.id)
      else
        import.update(messages: nil, state: :imported)
      end
    end
  end
end
