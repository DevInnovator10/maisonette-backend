# frozen_string_literal: true

module Salsify
    class ProductsImportInteractor < ApplicationInteractor
    include Salsify::ImportHelper

    before :validate_and_init
    before :prepare_taxonomies
    before :prepare_properties

    MATCHER = '**maisonette*_product*.csv'
    SOURCE_PATH = '/Spree/CSV'
    BACKUP_PATH = '/Spree/CSV/backup'

    def call
      ActiveRecord::Base.transaction do
        fetch
        parse
      end
      process
    end

    private

    def prepare_properties
      (Salsify::PRODUCT_PROPERTIES + Salsify::MULTI_VALUE_PRODUCT_PROPERTIES).each do |property_name|
        Spree::Property.create_with(presentation: property_name).find_or_create_by(name: property_name)
      end
    end

    def create_file_import(file)
      @product_imports ||= []
      @product_imports << Salsify::Import.create!(
        file_to_import: file,
        state: :created,
        import_type: :products
      )
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

    def parse
      @product_imports&.each do |import|
        options = { import: import, local_path: @local_path, delete_local_file: context.delete_local_file }
        import_context = Salsify::ParseInteractor.call(options)
        if import_context.success?
          import.update(messages: import_context.messages, state: :imported)
        else
          import.update(messages: import_context.messages, state: :failed)
          Sentry.capture_exception_with_message(
            Salsify::Exception.new(import_context.messages, resource_class: Salsify::Import, resource_id: import.id)
          )
        end
      end
    end

    def process
      Salsify::Import.by_type(:products).imported.find_each do |import|
        import.processing!
        import.salsify_import_rows.created.group_by(&:unique_key).each do |unique_key, rows|
          Salsify::ImportRowWorker.perform_async(unique_key, rows.pluck(:id))
        end
      end
    end

    def prepare_taxonomies
      Salsify::TAXONOMIES.each do |taxon_name|
        Spree::Taxonomy.find_or_create_by!(name: taxon_name).tap do |taxonomy|
          taxonomy.taxons.find_or_create_by!(name: taxon_name, parent_id: nil)
        end
      end
    end
  end
end
