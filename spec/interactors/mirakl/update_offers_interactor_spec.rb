# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::UpdateOffersInteractor, mirakl: true do
    describe 'hooks' do
    let(:interactor) { described_class.new }

    it 'has after_hooks' do
      expect(described_class.before_hooks).to eq [:prepare_affected_offers_log]
      expect(described_class.after_hooks).to eq [:process_offers, :ensure_all_offers_updated]
    end

    describe '#process_offers' do
      subject(:process_offers) { interactor.send :process_offers }

      let(:updated_skus) { %w[SKU1 SKU2 SKU3 SKU4 SKU5 SKU6 SKU7 SKU8 SKU9 SKU10 SKU11] }

      before do
        allow(Mirakl::ProcessOffersWorker).to receive(:perform_async)
        allow(interactor).to receive_messages(updated_skus: updated_skus)
        process_offers
      end

      it 'calls Mirakl::ProcessOffersWorker for every 10 skus' do
        expect(Mirakl::ProcessOffersWorker).to have_received(:perform_async).with(updated_skus[0...10])
        expect(Mirakl::ProcessOffersWorker).to have_received(:perform_async).with(updated_skus[10..-1])
      end
    end

    describe '#prepare_affected_offers_log' do
      subject(:prepare_affected_offers_log) { interactor.send :prepare_affected_offers_log }

      it 'sets affected_offers context' do
        expect { prepare_affected_offers_log }.to(
          change(interactor.context, :affected_offers).from(nil) { { deleted_offer: [], upserted_offer: [] } }
        )
      end
    end

    describe '#ensure_all_offers_updated' do
      subject(:ensure_all_offers_updated) { interactor.send :ensure_all_offers_updated }

      let(:interactor) { described_class.new(failed_offer_update: true) }

      context 'when ensure_all_offers_updated is true' do
        it 'fails the interactor' do
          expect { ensure_all_offers_updated }.to raise_error(Interactor::Failure)
        end
      end
    end
  end

  describe '#call' do
    subject(:update_offers) { described_class.call offers: offers_csv_string }

    let(:offers_csv_string) { 'offers_csv_string' }
    let(:offers_csv) { [] }

    before do
      allow(CSV).to receive_messages(parse: offers_csv)
    end

    it 'parses the offers csv string' do
      update_offers

      expect(CSV).to have_received(:parse).with(offers_csv_string, headers: true, col_sep: ';')
    end

    context 'when the offer is deleted' do
      let(:offers_csv) { [{ 'offer-id' => '2001', 'deleted' => 'true' }] }

      before { create :mirakl_offer, offer_id: 2001 }

      it 'destroys the offer' do
        expect { update_offers }.to change(Mirakl::Offer, :count).by(-1)
      end

      it 'collects the id in deleted_offer hash key' do
        update_offers

        expect(update_offers.affected_offers).to eq(deleted_offer: ['2001'], upserted_offer: [])
      end
    end

    context 'when the offer is not deleted' do
      let!(:mirakl_shop) { create :mirakl_shop }
      let!(:offer) { create :mirakl_offer, offer_id: 3001 }
      let(:offers_csv) do
        [
          {
            'shop-id' => mirakl_shop.shop_id.to_s,
            'offer-id' => offer.offer_id.to_s,
            'active' => 'true',
            'state-code' => '11',
            'product-sku' => 'SKU0101',
            'shop-sku' => 'MAIS123',
            'quantity' => '5',
            'origin-price' => '15.00',
            'price' => '12.00',
            'available-start-date' => '2001-07-01T04:00:00Z',
            'available-end-date' => '2099-07-15T04:00:00Z'
          }
        ]
      end

      before do
        update_offers
      end

      it 'updates the mirakl offer' do
        expect(offer.reload.attributes.with_indifferent_access).to(
          match(
            hash_including(shop_id: mirakl_shop.id,
                           active: true,
                           offer_state: '11',
                           sku: 'SKU0101',
                           shop_sku: 'MAIS123',
                           quantity: 5,
                           original_price: 15.00,
                           price: 12.00,
                           available_from: Time.parse('2001-07-01T04:00:00Z').in_time_zone,
                           available_to: Time.parse('2099-07-15T04:00:00Z').in_time_zone)
          )
        )
      end

      it 'collects the id in upserted_offer hash key' do
        update_offers

        expect(update_offers.affected_offers).to eq(deleted_offer: [], upserted_offer: ['3001'])
      end
    end

    context 'when an error is thrown' do
      let(:offers_csv) { [{ 'foo' => 'bar' }] }
      let(:exception) { StandardError.new 'foo' }
      let(:error_message) do
        I18n.t('errors.update_offer_error',
               class_name: described_class.to_s,
               e: exception.message,
               csv_row_hash: offers_csv[0].to_hash)
      end

      before do
        allow(Sentry).to receive(:capture_exception_with_message)
        allow(Mirakl::Offer).to receive(:find_or_initialize_by).and_raise(exception)

        update_offers
      end

      it 'call Sentry.capture_exception_with_message' do
        expect(Sentry).to have_received(:capture_exception_with_message).with(exception, message: error_message)
      end

      it 'sets failed_offer_update to true' do
        expect(update_offers.failed_offer_update).to eq true
        expect(update_offers).to be_a_failure
      end
    end
  end
end
