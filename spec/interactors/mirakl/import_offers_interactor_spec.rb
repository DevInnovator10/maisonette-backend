# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ImportOffersInteractor, mirakl: true do
  describe 'hooks' do
    let(:interactor) { described_class.new }

    it 'has before hooks' do
      expect(described_class.before_hooks).to eq [:set_start_time, :parse_updated_since, :default_retriable_options]
    end

    describe '#set_start_time', freeze_time: true do
      subject(:set_start_time) { interactor.send :set_start_time }

      before { set_start_time }

      it 'sets context.start_time to Time.current' do
        expect(interactor.context.start_time).to eq Time.current
      end
    end

    describe '#default_retriable_options' do
      subject(:default_retriable_options) { interactor.send :default_retriable_options }

      before { default_retriable_options }

      it 'sets default_retriable_options context' do
        expect(interactor.context.default_retriable_options).to eq(notify_exception: true)
      end
    end

    describe 'parse_updated_since' do
      subject(:parse_updated_since) { interactor.send :parse_updated_since }

      let(:interactor) { described_class.new updated_since: updated_since }
      let(:updated_since) { '2011-01-15 07:40:00' }

      before { parse_updated_since }

      it 'parses context.updated_since to a time' do
        expect(interactor.context.updated_since).to eq Time.zone.parse(updated_since)
      end
    end
  end

  describe '#call' do
    let(:import_offers) { described_class.new(updated_since: updated_since) }
    let(:updated_since) { nil }
    let(:offers_response) { instance_double(RestClient::Response, body: 'response_body') }
    let(:query) { '?offer_query' }
    let(:update_offers_interactor) do
      instance_double('Context', success?: result, affected_offers:
        {
          deleted_offer: [deleted_offer],
          upserted_offer: [upserted_offer]
        })
    end
    let(:deleted_offer) { '1000' }
    let(:upserted_offer) { '2000' }
    let(:rails_logger) { instance_double ActiveSupport::Logger, warn: true }
    let(:result) { true }

    before do
      allow(import_offers).to receive_messages(get: offers_response, query: query)
      allow(Mirakl::UpdateOffersInteractor).to receive(:call).and_return(update_offers_interactor)
      allow(Mirakl::Update).to receive(:create)
      allow(Rails).to receive(:logger).and_return(rails_logger)

      import_offers.call
    end

    context 'when Mirakl::UpdateOffersInteractor fails' do
      let(:result) { false }

      it 'does not create a Mirakl::Update' do
        expect(Mirakl::Update).not_to have_received(:create)
      end
    end

    context 'when UpdateOffersInteractor returns deleted offer id' do
      it 'logs offer id' do
        expect(rails_logger).to have_received(:warn).with(
          deleted_offer: [deleted_offer], upserted_offer: [upserted_offer]
        )
      end
    end

    it 'calls GET on /offers/export with a query' do
      expect(import_offers).to have_received(:get).with("/offers/export?#{query}")
    end

    it 'calls Mirakl::UpdateOffersInteractor with response body' do
      expect(Mirakl::UpdateOffersInteractor).to have_received(:call).with(offers: offers_response.body)
    end
  end

  describe '#query' do
    let(:import_offers) { described_class.new(updated_since: updated_since) }
    let(:query) { import_offers.send(:query) }

    context 'when updated_since is nil' do
      let(:updated_since) { nil }

      it 'returns include_inactive_offers=true' do
        expect(query).to eq 'include_inactive_offers=true'
      end
    end

    context 'when updated_since is a time' do
      let(:updated_since) { Time.current }
      let(:last_request_date_regex) { /last_request_date=#{updated_since.iso8601}/ }

      it 'returns last_request_date' do
        expect(query).to eq "last_request_date=#{updated_since.iso8601}"
      end
    end
  end
end
