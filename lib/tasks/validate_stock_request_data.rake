# frozen_string_literal: true

namespace :validate_stock_request_data do
  desc 'Delete Invalid data from Maisonette Stock Request Model'
  task validate_record: :environment do
    Maisonette::StockRequest.find_in_batches(batch_size: 1000) do |stock_requests|
      stock_requests.each do |stock_request|
        stock_request.destroy if stock_request.invalid?
      end
    end
  end
end
