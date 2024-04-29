# frozen_string_literal: true

module Maisonette
  class OrphanSalePriceDeletionMailer < Spree::BaseMailer
    layout false

    def delete_all_email
      attachments['orphan_sale_prices.csv'] = File.read(file_path) if file_path

      @recipient = params[:recipient]
      @orphan_sale_price_count = params[:orphan_sale_price_count]

      mail(
        to: [@recipient],
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
      [env, 'Maisonette | Orphan Sale Price Deletion'].compact.join(' ')
    end
  end
end
