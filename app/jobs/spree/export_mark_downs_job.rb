# frozen_string_literal: true

require 'csv'

module Spree
  class ExportMarkDownsJob < ApplicationJob
    queue_as :default

    EXPORT_ATTRIBUTES = [
      :title,
      :active_and_current?,
      :start_at,
      :end_at,
      :final_sale,
      :liability_split,
      :included_taxon_names,
      :excluded_taxon_names,
      :included_vendor_names,
      :excluded_vendor_names
    ].freeze

    after_perform { send_notification }

    def perform(mark_down_ids:, user:)
      @user = user

      prepare_mark_downs(mark_down_ids)
      generate_csv
      upload_csv
    end

    private

    def prepare_mark_downs(mark_down_ids)
      @mark_downs = Spree::MarkDown.where(id: mark_down_ids)
    end

    def generate_csv
      @csv_data = csv_headers
      @mark_downs.each do |mark_down|
        @csv_data << mark_down_row(mark_down)
      end
      @csv_data
    end

    def csv_headers
      CSV.generate_line(
        EXPORT_ATTRIBUTES.map { |attr| I18n.t("spree.mark_downs.export_headers.#{attr}") }
      )
    end

    def mark_down_row(mark_down)
      mark_down = Spree::MarkDowns::ExportDecorator.new(mark_down)
      CSV.generate_line(mark_down.slice(*EXPORT_ATTRIBUTES).values)
    end

    def directory
      'exports/' + self.class.name.demodulize.underscore
    end

    def object_path
      "#{directory}/user#{@user.id}_#{DateTime.now.to_i}_export.csv"
    end

    def upload_csv
      S3.put(object_path, @csv_data)
      @csv_data
    end

    def generate_presigned_url
      S3.get_presigned_url(object_path, response_content_disposition: 'attachment')
    end

    def send_notification
      options = { url: generate_presigned_url, user: @user }
      Spree::ExportMarkDownsMailer.notify(options).deliver_now
    end
  end
end
