# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :order_management do
    desc 'Create Sales Orders and Order Item Summaries records'
  task create_sales_orders_records: :environment do
    options = BatchTaskOptionParser.new('Spree::Order', ENV['FROM'], ENV['TO'], ENV['BATCH_SIZE'])
    options.perform!
    next unless options.input.downcase == 'y'

    records = options.solidus_model.where(completed_at: options.from..options.to)
    records.find_in_batches(batch_size: options.batch_size) do |group|
      OrderManagement::CreateHistoricalSalesOrderWorker.perform_async(group.pluck(:id))
      puts "Enqueued #{group.size} orders"
    end
  end

  desc 'Create Order and LineItem csv'
  task create_historical_order_data_csv: :environment do
    options = BatchTaskOptionParser.new('Spree::Order', ENV['FROM'], ENV['TO'], ENV['BATCH_SIZE'])
    options.perform!
    next unless options.input.downcase == 'y'

    records = options.solidus_model.where(completed_at: options.from..options.to)
    puts 'No orders found' && next if records.empty?
    stream_id = DateTime.now.to_s
    records.find_in_batches(batch_size: options.batch_size) do |group|
      order_ids = group.pluck(:id)
      line_item_ids = Spree::LineItem.where(order_id: order_ids).pluck(:id)
      OrderManagement::CreateRecordsCsvWorker.perform_async('Spree::Order', order_ids, stream_id)
      OrderManagement::CreateRecordsCsvWorker.perform_async('Spree::LineItem', line_item_ids, stream_id)
      puts "Enqueued #{group.size} orders"
    end
  end

  desc 'Fetch historical SalesOrder order_management_ref'
  task fetch_historical_sales_order: :environment do
    options = BatchTaskOptionParser.new('Spree::Order', ENV['FROM'], ENV['TO'], ENV['BATCH_SIZE'])
    options.perform!
    next unless options.input.downcase == 'y'

    records = solidus_model_scope(options.solidus_model).left_outer_joins(:sales_order)
                                                        .where(order_management_sales_orders: {
                                                                 order_management_ref: nil
                                                               })
                                                        .where(completed_at: options.from..options.to)
    puts 'No records found' && next if records.empty?
    records.find_in_batches(batch_size: options.batch_size) do |group|
      OrderManagement::FetchHistoricalSalesOrderWorker.perform_async(group.pluck(:id))
      puts "Enqueued #{group.size} records"
    end
  end
end
# rubocop:enable Metrics/BlockLength
