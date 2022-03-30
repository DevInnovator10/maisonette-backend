# frozen_string_literal: true

module Maisonette
  class SaleExportMailer < Spree::BaseMailer

    layout false

    def export_email
      attachments[params[:attachment_name]] = File.read(params[:attachment_path])

      mail(
        to: params[:recipient],
        from: Spree::Store.default.mail_from_address,
        subject: params[:subject]
      )
    end
  end
end
