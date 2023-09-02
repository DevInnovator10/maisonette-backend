# frozen_string_literal: true

module Salsify
  class MiraklProductsImportInteractor < ApplicationInteractor
    include Salsify::ImportHelper

    before :validate_and_init

    PRODUCT_MATCHER = '*mirakl_product_feed_maisonette*.csv'
    SOURCE_PATH = '/Mirakl/salsify_output'
    BACKUP_PATH = SOURCE_PATH + '/backup'

    def call
      context.mirakl_product_export_jobs = []
      fetch(PRODUCT_MATCHER)
    end

    private

    def fetch(matcher)
      ftp = Salsify::FTP.new(matcher: matcher, source_path: SOURCE_PATH, backup_path: BACKUP_PATH)
      ftp.fetch(local_path: @local_path) do |file|
        context.mirakl_product_export_jobs << Salsify::MiraklProductExportJob.create.tap do |mirakl_product_export_job|
          mirakl_product_export_job.products.attach(io: File.open("#{@local_path}/#{file}"),
                                                    filename: file,
                                                    content_type: 'text/csv')
        end
      end
    end
  end
end
