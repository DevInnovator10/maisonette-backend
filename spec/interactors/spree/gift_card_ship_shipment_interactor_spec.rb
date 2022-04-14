# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::GiftCardShipShipmentInteractor do
  describe '#call' do
    context 'when it is successful' do
      subject(:call) { described_class.call gift_card: gift_card_1 }

      let(:gift_card_1) { instance_double Spree::GiftCard, sent_at: sent_at_1 }
      let(:gift_card_2) { instance_double Spree::GiftCard, sent_at: sent_at_2 }
      let(:line_item) do
        instance_double Spree::LineItem,
                        gift_cards: [gift_card_1, gift_card_2],
                        inventory_units: [inventory_unit_1, inventory_unit_2]
      end
      let(:inventory_unit_1) do
        instance_double Spree::InventoryUnit
      end
      let(:inventory_unit_2) { instance_double Spree::InventoryUnit }
      let(:shipment) { instance_double Spree::Shipment, ship: true, line_items: [line_item] }
      let(:sent_at_1) {}
      let(:sent_at_2) {}

      before do
        allow(gift_card_1).to receive_messages(line_item: line_item)
        allow(inventory_unit_1).to receive_messages(shipment: shipment)

        call
      end

      context 'when all gift cards have been sent' do
        let(:sent_at_1) { Date.current }
        let(:sent_at_2) { Date.current }

        it 'ships the shipment' do
          expect(shipment).to have_received(:ship)
        end
      end

      context 'when not all gift cards have been sent' do
        let(:sent_at_1) { Date.current }
        let(:sent_at_2) {}

        it 'does not ships the shipment' do
          expect(shipment).not_to have_received(:ship)
        end
      end
    end

    context 'when there are errors' do
      subject(:call) { interactor.call }

      let(:interactor) { described_class.new gift_card: gift_card_1 }
      let(:gift_card_1) { instance_double Spree::GiftCard }
      let(:exception) { StandardError.new 'some adjustment error' }

      before do
        allow(gift_card_1).to receive(:line_item).and_raise(exception)
        allow(interactor).to receive_messages(rescue_and_capture: true)

        call
      end

      it 'call rescue_and_capture with the exception' do
        expect(interactor).to have_received(:rescue_and_capture).with(exception)
      end
    end
  end
end
