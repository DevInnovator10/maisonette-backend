# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::OrderShipping::ShipCarton, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:described_class) { Spree::OrderShipping }

  let(:order) { create(:order_ready_to_ship, line_items_count: 1) }

  def emails
    ActionMailer::Base.deliveries
  end

  shared_examples 'carton shipping' do
    it 'marks the inventory units as shipped' do
      expect { ship_carton }.to change { order.inventory_units.reload.map(&:state) }.from(['on_hand']).to(['shipped'])
    end

    it 'updates the carton shipping information' do
      now = Time.current
      travel_to(now) do
        expect { ship_carton }.to change { carton.reload.shipped_at }.from(nil).to be_within(1.second).of(now)
      end
    end

    describe 'shipment email' do
      let(:mailer) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

      before do
        allow(Spree::CartonMailer).to receive(:shipped_email).and_return(mailer)
      end

      it 'sends a shipment email' do
        ship_carton
        expect(mailer).to have_received(:deliver_later)
      end
    end

    it 'updates the order shipment state' do
      expect { ship_carton }.to change { order.reload.shipment_state }.from('ready').to('shipped')
    end

    it 'updates shipment.shipped_at' do
      now = Time.current
      travel_to(now) do
        expect { ship_carton }.to change { shipment.reload.shipped_at }.from(nil).to be_within(1.second).of(now)
      end
    end

    it 'updates shipment.tracking' do
      expect { ship_carton }.to change { shipment.reload.tracking }.to('tracking')
    end

    it 'updates order.updated_at' do
      future = 1.minute.from_now
      expect do
        travel_to(future) do
          ship_carton
        end
      end.to change(order, :updated_at).to be_within(1.second).of(future)
    end
  end

  describe '#ship_carton' do
    subject(:ship_carton) { order.shipping.ship_carton(carton) }

    let(:shipment) { order.shipments.to_a.first }
    let(:carton) { create(:carton, shipped_at: nil, tracking: 'tracking', inventory_units: shipment.inventory_units) }

    it_behaves_like 'carton shipping'

    context 'when not all units are shippable' do
      let(:order) { create(:order_ready_to_ship, line_items_count: 2) }
      let(:shippable_line_item) { order.line_items.first }
      let(:unshippable_line_item) { order.line_items.last }

      before do
        unshippable_line_item.inventory_units.each(&:cancel!)
      end

      it 'only ships the shippable ones' do
        expect(ship_carton.inventory_units.shipped).to match_array(shippable_line_item.inventory_units)
      end
    end

    context 'when all units are canceled or shipped' do
      let(:order) { create(:order_ready_to_ship, line_items_count: 2) }

      before { Spree::OrderCancellations.new(order).short_ship([order.inventory_units.first]) }

      it 'updates the order shipment state' do
        expect { ship_carton }.to change { order.reload.shipment_state }.from('ready').to('shipped')
      end
    end

    context 'with an external_number' do
      subject(:ship_carton) do
        order.shipping.ship_carton(
          carton,
          external_number: 'some-external-number'
        )
      end

      it 'sets the external_number' do
        expect(ship_carton.reload.external_number).to eq 'some-external-number'
      end
    end

    context 'with a tracking number' do
      subject(:ship_carton) do
        order.shipping.ship_carton(
          carton,
          tracking_number: 'tracking-number'
        )
      end

      it 'sets the tracking-number' do
        expect(ship_carton.tracking).to eq 'tracking-number'
      end
    end

    context 'when told to suppress the mailer' do
      subject(:ship_carton) do
        order.shipping.ship_carton(
          carton,
          suppress_mailer: true
        )
      end

      let(:mailer) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

      before do
        allow(Spree::CartonMailer).to receive(:shipped_email).and_return(mailer)
      end

      it 'does not send a shipment email' do
        ship_carton
        expect(mailer).not_to have_received(:deliver_later)
      end
    end
  end
end
