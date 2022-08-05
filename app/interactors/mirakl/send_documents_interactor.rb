# frozen_string_literal: true

module Mirakl
  class SendDocumentsInteractor < ApplicationInteractor
    # Input:
    # - shop_id: destination Mirakl shop
    # - archive: documents archive to send
    # - order_ids: mirakl orders
    # - total_items_quantity: total orders item quantity
    # - documents_time: starting date/hour for documents processing
    # - batch: batch informations => [group, groups]
    def call
      shop = Mirakl::Shop.find context.shop_id
      args = prepare_mailer_args(shop)
      begin
        args[:archive_path] = temp_file.path
        Mirakl::ShopDocumentsMailer.with(args).shop_documents_email.deliver_now!
        # rubocop:disable Rails/SkipsModelValidations
        mirakl_orders.update_all(bulk_document_sent: true)
        mirakl_orders_with_fixed_errors.update_all(bulk_document_sent: true)
        # rubocop:enable Rails/SkipsModelValidations
      ensure
        temp_file.close
        temp_file.unlink
      end
    end

    private

    def mirakl_orders
      @mirakl_orders ||= Mirakl::Order.where(id: context.order_ids, bulk_document_error_sent: false)
    end

    def mirakl_orders_with_fixed_errors
      @mirakl_orders_with_fixed_errors ||= Mirakl::Order.where(id: context.order_ids, bulk_document_error_sent: true)
    end

    def prepare_mailer_args(shop)
      batch = context.batch || [1, 1]
      {
        recipient: shop.email,
        vendor_name: shop.name,

        orders: mirakl_orders.pluck(:logistic_order_id),
        orders_with_fixed_errors: mirakl_orders_with_fixed_errors.pluck(:logistic_order_id),
        total_items_quantity: context.total_items_quantity,
        documents_time: context.documents_time,
        batch_group: batch[0],
        batch_groups: batch[1]
      }
    end

    def temp_file
      @temp_file ||= begin
        Tempfile.new("bulk_documents_shop#{context.shop_id}").tap do |temp|
          temp.write(context.archive)
          temp.rewind
        end
      end
    end
  end
end
