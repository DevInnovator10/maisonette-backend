# frozen_string_literal: true

require 'zip'

module Mirakl
  class ProcessDocumentsInteractor < ApplicationInteractor
    DOCUMENT_TYPES = %w[customs_form order_label packing-slip].freeze

    # Input:
    # - documents: documents ZIP archive from Mirakl downloads endpoint
    # - manifest: CSV orders manifest
    # Output:
    # - archive: ZIP archive data with the grouped documents and CSV orders manifest
    def call
      files = DOCUMENT_TYPES.each_with_object({}) do |type, list|
        data = combine_documents_by_type(context.documents, type)
        list["#{type}s.pdf"] = data if data
      end
      prepare_archive(files)
    end

    private

    def combine_documents_by_type(documents, type)
      files = {}
      ::Zip::InputStream.open(StringIO.new(documents)) do |zio|
        while (entry = zio.get_next_entry)
          tokens = entry.name.match(type)
          next unless tokens

          files[entry.name] = zio.read
        end
      end
      files.sort.map(&:last).inject(CombinePDF.new) do |buffer, data|
        buffer << CombinePDF.parse(data)
      end
    end

    def prepare_archive(files)
      archive = ::Zip::OutputStream.write_buffer do |zio|
        files.each do |name, data|
          zio.put_next_entry(name)
          zio.write(data.to_pdf)
        end
        zio.put_next_entry('orders_manifest.csv')
        zio.write(context.manifest)
      end
      archive.flush
      context.archive = archive.string
    end
  end
end
