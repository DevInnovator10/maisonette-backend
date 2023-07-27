# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::StockRequestsNotificationWorker do
  describe '#perform' do
    subject(:perform) { worker.perform }

    let(:worker) { described_class.new }
    let(:request_double) { class_double Maisonette::StockRequest }

    it 'collects the stock requests with purchasable variants' do
      allow(Maisonette::StockRequest).to receive(:queued).and_return request_double
      allow(request_double).to receive(:with_purchasable_variant).and_return request_double
      allow(request_double).to receive(:order)

      perform
      expect(Maisonette::StockRequest).to have_received :queued
      expect(request_double).to have_received :with_purchasable_variant
      expect(request_double).to have_received(:order).with 'maisonette_stock_requests.created_at'
    end

    context 'when stock requests exist' do
      let(:stock_requests) { create_list :stock_request, 3, state: :queued }
      let(:stock_requests_query) { class_double Maisonette::StockRequest }

      before do
        allow(worker).to receive(:stock_requests).and_return stock_requests_query
        allow(stock_requests_query).to receive(:find_each).and_yield(stock_requests[0])
                                                          .and_yield(stock_requests[1])
                                                          .and_yield(stock_requests[2])
      end

      context 'when it is successful' do

        before { perform }

        it 'calls notify on each of the stock requests returned' do
          stock_requests.map(&:reload)

          expect(stock_requests.map(&:state).uniq).to eq %w[notified]
          expect(stock_requests.all?(&:sent_at)).to be true
        end
      end

      context 'when a stock request fails with Maisonette::StockRequest::EmailAlreadyOnWaitlistException' do
        before do
          stock_requests[0].dup.update(state: :notified)
          perform
        end

        it 'destroys the stock request' do
          expect(Maisonette::StockRequest.find_by(id: stock_requests[0].id)).to be_nil

          expect(stock_requests[1].reload.state).to eq 'notified'
          expect(stock_requests[2].reload.state).to eq 'notified'
          expect(stock_requests[1].sent_at).not_to be_nil
          expect(stock_requests[2].sent_at).not_to be_nil
        end
      end
    end
  end
end
