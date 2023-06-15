# frozen_string_literal: true

module Maisonette
  class DeleteSaleSkuConfigurationsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :maisonette_sales

    def perform(sale_id, offer_settings_params)
      raise Maisonette::CreateSaleSkuConfigurationsError, 'Empty offer settings params' if offer_settings_params.empty?

      sale = ::Maisonette::Sale.find(sale_id)
      configuration_count = sale.sale_sku_configurations.count
      return unless configuration_count.positive?

      csv_file = build_csv(sale)
      sale.sale_sku_configurations.destroy_all
      send_email(sale, configuration_count, csv_file, offer_settings_params['updated_by_id'])
    end

    private

    def build_csv(sale)
      return if sale.nil?

      result = ::Maisonette::BuildSaleCsvInteractor.call(
        collection: ::Maisonette::SaleSkuConfigurationPresenter.new(sale).call,
        csv_filename: ['deleted_products', '.csv']
      )
      result.file
    end

    def send_email(sale, configuration_count, csv_file, updated_by_id)
      Maisonette::SaleConfigurationDeleteAllMailer.with(
        sale_name: sale.name,
        recipient: ::Spree::User.find_by(id: updated_by_id)&.email,
        configuration_count: configuration_count,
        file_path: csv_file&.path
      ).delete_all_email.deliver_now!.tap do |_|
        csv_file&.close
        csv_file&.unlink
      end
    end
  end

  class Maisonette::CreateSaleSkuConfigurationsError < StandardError; end # rubocop:disable Style/ClassAndModuleChildren
end
