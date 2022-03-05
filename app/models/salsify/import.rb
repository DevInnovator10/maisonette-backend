# frozen_string_literal: true

module Salsify
  class Import < Base
    enum state: {
      created: 'created',
      processing: 'processing',
      failed: 'failed',
      imported: 'imported',
      completed: 'completed'
    }
    enum import_type: {
      brands: 'brands',
      products: 'products'
    }

    has_many :salsify_import_rows,
             class_name: 'Salsify::ImportRow',
             foreign_key: :salsify_import_id,
             inverse_of: :salsify_import,
             dependent: :destroy
    alias_attribute :rows, :salsify_import_rows

    validates :file_to_import, presence: true, allow_blank: false
    validates :import_type, presence: true, allow_blank: false
    validates :state, presence: true

    serialize :messages, JSON

    scope :ordered, -> { order(:id) }
    scope :by_type, ->(type) { where(import_type: type) }
    scope :not_notified, -> { where(notified_at: nil) }

    def mark_as_notified
      update(notified_at: Time.zone.now)
    end

    def import_file
      Pathname.new(Maisonette::Config.fetch('salsify.local_path')).join file_to_import
    end

    def import_rows_completed?
      !salsify_import_rows.where.not(state: :completed).exists?
    end

    def import_rows_processed?
      (salsify_import_rows.pluck(:state).uniq - %w[failed completed]).none?
    end
  end
end
