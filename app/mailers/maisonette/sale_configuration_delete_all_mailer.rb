# frozen_string_literal: true

module Maisonette
  class SaleConfigurationDeleteAllMailer < Spree::BaseMailer
    layout false

    def delete_all_email
      attachments['deleted_products.csv'] = File.read(file_path) if file_path

      @recipient = params[:recipient]
      @configuration_count = params[:configuration_count]

      mail(
        to: [@recipient, Maisonette::Config.fetch('mail.merch_email')],
        from: Spree::Store.default.mail_from_address,
        subject: subject
      )
    end

    private

    def file_path
      params[:file_path]

    end

    def subject
      env = Rails.env.production? ? '' : "[#{Rails.env.upcase}]"
      [env, 'Maisonette | Deleted Products from', params[:sale_name].to_s].compact.join(' ')
    end
  end
end
