# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::RecreateFailedLabelsWorker, mirakl: true do
  let!(:mirakl_order_shipping_error_1) { create :mirakl_order, state: 'SHIPPING', shipment: shipment_1 }
  let!(:mirakl_order_shipped) { create :mirakl_order, state: 'SHIPPED', shipment: shipment_2 }
  let!(:mirakl_order_waiting_acceptance) { create :mirakl_order, state: 'WAITING_ACCEPTANCE', shipment: shipment_3 }
  let!(:mirakl_order_waiting_debit) { create :mirakl_order, state: 'WAITING_DEBIT_PAYMENT', shipment: shipment_4 }
  let!(:mirakl_order_shipping_wrong_error) { create :mirakl_order, state: 'SHIPPING', shipment: shipment_5 }
  let!(:mirakl_order_shipping_error_2) { create :mirakl_order, state: 'SHIPPING', shipment: shipment_6 }
  let!(:mirakl_order_shipping_error_3) { create :mirakl_order, state: 'SHIPPING', shipment: shipment_7 }
  let!(:mirakl_order_shipped_with_tracking) { create :mirakl_order, state: 'SHIPPED', shipment: shipment_8 }
  let(:shipment_1) { create :shipment, easypost_error: easypost_error_1, tracking: nil }
  let(:shipment_2) { create :shipment, easypost_error: easypost_error_1, tracking: nil }
  let(:shipment_3) { create :shipment, easypost_error: easypost_error_1, tracking: nil }
  let(:shipment_4) { create :shipment, easypost_error: easypost_error_1, tracking: nil }
  let(:shipment_5) { create :shipment, easypost_error: 'some other error message', tracking: nil }
  let(:shipment_6) { create :shipment, easypost_error: easypost_error_2, tracking: nil }
  let(:shipment_7) { create :shipment, easypost_error: easypost_error_3, tracking: nil }
  let(:shipment_8) { create :shipment, easypost_error: easypost_error_1, tracking: 'Some tracking number' }
  let(:easypost_error_1) { 'Error contacting carrier: Carrier did not respond.' }
  let(:easypost_error_2) { EASYPOST_DATA[:error_codes]['SHIPMENT.POSTAGE.NO_RESPONSE'] }
  let(:easypost_error_3) { Easypost::Order::NO_RATES_ERROR }

  before do
    allow(Mirakl::Easypost::SendLabelsOrganizer).to receive(:call!)
    allow(Sentry).to receive(:capture_message)
  end

  context 'when there are less that 10 mirakl orders' do
    before { described_class.new.perform }

    # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
    it 'calls Mirakl::Easypost::SendLabelsOrganizer with the mirakl orders' do
      expect(Mirakl::Easypost::SendLabelsOrganizer).to(
        have_received(:call!).with(mirakl_order: mirakl_order_shipping_error_1, destroy_easypost_orders: true)
      )
      expect(Mirakl::Easypost::SendLabelsOrganizer).to(
        have_received(:call!).with(mirakl_order: mirakl_order_shipped, destroy_easypost_orders: true)
      )
      expect(Mirakl::Easypost::SendLabelsOrganizer).to(
        have_received(:call!).with(mirakl_order: mirakl_order_waiting_debit, destroy_easypost_orders: true)
      )
      expect(Mirakl::Easypost::SendLabelsOrganizer).to(
        have_received(:call!).with(mirakl_order: mirakl_order_shipping_error_2, destroy_easypost_orders: true)
      )
      expect(Mirakl::Easypost::SendLabelsOrganizer).to(
        have_received(:call!).with(mirakl_order: mirakl_order_shipping_error_3, destroy_easypost_orders: true)
      )

      expect(Mirakl::Easypost::SendLabelsOrganizer).not_to(
        have_received(:call!).with(mirakl_order: mirakl_order_waiting_acceptance, destroy_easypost_orders: true)
      )
      expect(Mirakl::Easypost::SendLabelsOrganizer).not_to(
        have_received(:call!).with(mirakl_order: mirakl_order_shipping_wrong_error, destroy_easypost_orders: true)
      )
      expect(Mirakl::Easypost::SendLabelsOrganizer).not_to(
        have_received(:call!).with(mirakl_order: mirakl_order_shipped_with_tracking, destroy_easypost_orders: true)
      )
    end
    # rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength

    context 'when there are no easypost errors' do
      let(:easypost_error_1) {}
      let(:easypost_error_2) {}
      let(:easypost_error_3) {}

      it 'does not call Mirakl::Easypost::SendLabelsOrganizer on any orders' do
        expect(Mirakl::Easypost::SendLabelsOrganizer).not_to have_received(:call!)
      end
    end
  end

  context 'when there are 10 or more mirakl orders' do
    let!(:mirakl_order_1) { create :mirakl_order, state: 'SHIPPING', shipment: shipment_8 }
    let!(:mirakl_order_2) { create :mirakl_order, state: 'SHIPPING', shipment: shipment_9 }
    let!(:mirakl_order_3) { create :mirakl_order, state: 'SHIPPING', shipment: shipment_10 }
    let!(:mirakl_order_4) { create :mirakl_order, state: 'SHIPPING', shipment: shipment_11 }
    let(:shipment_8) { create :shipment, easypost_error: easypost_error_1, tracking: nil }
    let(:shipment_9) { create :shipment, easypost_error: easypost_error_1, tracking: nil }
    let(:shipment_10) { create :shipment, easypost_error: easypost_error_1, tracking: nil }
    let(:shipment_11) { create :shipment, easypost_error: easypost_error_1, tracking: nil }

    let(:message) do
      "#{described_class.name} - Attempting to recreate '10' labels - if this continues we may have an issue"
    end

    before do
      mirakl_order_1
      mirakl_order_2
      mirakl_order_3
      mirakl_order_4

      described_class.new.perform
    end

    it 'does capture_message via Sentry' do
      expect(Sentry).to have_received(:capture_message).with(message)
    end
  end
end
