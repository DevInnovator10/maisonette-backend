# frozen_string_literal: true

module Mirakl
  class ShopDocumentsMailer < Spree::BaseMailer
    include MailerHelper

    # Input parameters:
    # - archive_path
    # - documents_time
    # - orders
    # - total_items_quantity
    # - recipient
    # - batch_group
    # - batch_groups
    def shop_documents_email
      prepare_context
      attachments["documents_#{documents_time.strftime('%Y-%m-%d_%H%M')}.zip"] = File.read(params[:archive_path])
      mail(to: params[:recipient],
           bcc: [Maisonette::Config.fetch('mail.ops_support_email')],
           from: Spree::Store.default.mail_from_address,
           subject: @subject)
    end

    private

    def documents_time
      @documents_time ||= DateTime.parse(params[:documents_time].to_s)
    end

    def prepare_context # rubocop:disable Metrics/AbcSize
      @orders = params[:orders]
      @orders_with_fixed_errors = params[:orders_with_fixed_errors]
      @begin_time = (documents_time - 1.hour).strftime('%Y-%m-%d %H:%M')
      @end_time = documents_time.strftime('%Y-%m-%d %H:%M')
      @subject = I18n.t('spree.mail.mirakl_shop_documents.subject',
                        vendor: params[:vendor_name],
                        datetime: @end_time)
      @subject += " - #{params[:batch_group]} of #{params[:batch_groups]}" if params[:batch_groups].to_i > 1
      @total_items_quantity = params[:total_items_quantity]
    end
  end
end
