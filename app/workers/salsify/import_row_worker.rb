# frozen_string_literal: true

require 'with_advisory_lock'

module Salsify
    class ImportRowWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'product_row_worker',
                    lock: :while_executing,
                    lock_args_method: ->(args) { [args.first] }

    def perform(_unique_key, import_row_ids) # rubocop:disable Metrics/MethodLength
      @variant_skus_processed = []
      @primary_row = true
      @different_variant_group_attributes = :first_row

      Salsify::ImportRow.where(id: import_row_ids).find_each do |import_row|
        process_result = process_row(import_row)
        update_import_row(import_row, row_attributes(process_result), process_result[:context])
        @primary_row = false
        @different_variant_group_attributes = Salsify.main_option_value_name(import_row.data)
      rescue StandardError => e
        import_row.update(messages: e.message, state: :failed)
        Sentry.capture_exception_with_message(e)
      end

      Mirakl::ProcessOffersWorker.perform_async(@variant_skus_processed) if @variant_skus_processed.any?
    end

    private

    def row_attributes(result)
      if result[:state] == :failed
        { messages: result[:context].messages, state: result[:state], spree_product: result[:context].product }
      else
        { messages: result[:context].importer_log_info, state: result[:state], spree_product: result[:context].product }
      end
    end

    def process_row(row)
      data = row.data
      pdp_variant_enabled = Flipper.enabled?(:pdp_variant, row)
      result = process_data(data, pdp_variant_enabled: pdp_variant_enabled,
                                  rename_product_enabled: Flipper.enabled?(:rename_product, row))
      state = if result.success?
                @variant_skus_processed += result.variant_skus_processed
                :imported
              else
                :failed
              end

      MarkDiscontinuedInteractor.call(action: data['Action'], row: data, pdp_variant_enabled: pdp_variant_enabled)
      { context: result, state: state }
    end

    def process_data(data, pdp_variant_enabled: nil, rename_product_enabled: nil)
      Spree::Variant.with_advisory_lock("importing variant #{data['Marketplace SKU']}", timeout_seconds: 60) do
        Salsify::ProcessProductOrganizer.call(
          row: data,
          import_product: primary_row?,
          different_variant_group_attributes: different_variant_group_attributes?(data) && pdp_variant_enabled,
          pdp_variant_enabled: pdp_variant_enabled,
          rename_product_enabled: rename_product_enabled
        )
      end
    end

    def update_import_row(import_row, result_attributes, processed_context)
      return import_row.update(result_attributes) unless result_attributes[:state] == :imported

      if different_variant_group_attributes?(import_row.data) && processed_context.pdp_variant_enabled
        import_row.update(result_attributes)
        Salsify::ImportProductImagesWorker.perform_async(import_row.id, processed_context.variant_group_attributes&.id)
      elsif primary_row?
        import_row.update(result_attributes)
        Salsify::ImportProductImagesWorker.perform_async(import_row.id, nil)
      else
        result_attributes[:state] = :completed
        import_row.update(result_attributes)
      end
    end

    def primary_row?
      @primary_row == true
    end

    def different_variant_group_attributes?(data)
      return true if @different_variant_group_attributes == :first_row

      @different_variant_group_attributes != Salsify.main_option_value_name(data)
    end
  end
end
