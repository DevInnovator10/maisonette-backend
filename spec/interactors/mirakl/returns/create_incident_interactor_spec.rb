# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Returns::CreateIncidentInteractor, mirakl: true do
  describe '#call' do
    let(:create_incident_interactor) { described_class.new return_authorization: return_authorization }
    let(:return_authorization) do
      instance_double Spree::ReturnAuthorization, number: 'RA-123', tracking_number: 'TR-456'
    end
    let(:order_lines) { [order_line1, order_line2] }
    let(:order_line1) do
      instance_double Mirakl::OrderLine,
                      id: 1,
                      update: true,
                      order: mirakl_order,
                      line_item: line_item1,
                      mirakl_order_line_id: 'R123-A1',
                      state: 'SHIPPING'
    end
    let(:order_line2) do
      instance_double Mirakl::OrderLine,
                      id: 2,
                      update: true,
                      line_item: line_item2,
                      mirakl_order_line_id: 'R123-A2',
                      state: 'SHIPPED'
    end
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: logistic_order_id }
    let(:line_item1) { instance_double Spree::LineItem }
    let(:line_item2) { instance_double Spree::LineItem }
    let(:logistic_order_id) { 'R123-A' }
    let(:return_authorization_hash) do
      { ra_number: return_authorization.number,
        ra_tracking: return_authorization.tracking_number,
        order_lines: [{ order_line_id: order_line1.mirakl_order_line_id,
                        quantity: 3 },
                      { order_line_id: order_line2.mirakl_order_line_id,
                        quantity: 5 }] }
    end

    before do
      allow(Mirakl::Returns::OpenNewIncidentInteractor).to receive(:call)
      allow(Mirakl::Returns::UpdateOrderLineRAInteractor).to receive(:call)
      allow(Mirakl::OrderLine).to receive_messages(part_of_return_authorization: order_lines)
      allow(create_incident_interactor).to receive(:quantity).with(order_line1.line_item).and_return(3)
      allow(create_incident_interactor).to receive(:quantity).with(order_line2.line_item).and_return(5)
    end

    it 'calls Mirakl::Returns::OpenNewIncidentInteractor on each Mirakl::OrderLine' do
      create_incident_interactor.call

      order_lines.each do |order_line|
        expect(Mirakl::Returns::OpenNewIncidentInteractor).to(have_received(:call).with(mirakl_order_line: order_line))
      end
    end

    it 'updates reach Mirakl::OrderLine with the RA' do
      create_incident_interactor.call

      expect(order_lines).to all have_received(:update).with(return_authorization: return_authorization)
    end

    it 'calls Mirakl::Returns::UpdateOrderLineRA with the return authorization information' do
      create_incident_interactor.call

      expect(Mirakl::Returns::UpdateOrderLineRAInteractor).to(
        have_received(:call).with(mirakl_order_id: logistic_order_id,
                                  return_authorization_hash: return_authorization_hash)
      )
    end

    context 'when one Mirakl::OrderLine is in an invalid state' do
      before { allow(order_line2).to receive(:state).and_return('INCIDENT_OPEN') }

      it 'opens incident for valid order lines and raises an error' do
        expect { create_incident_interactor.call }.to raise_exception(
          ::Mirakl::Returns::CreateIncidentInteractor::InvalidStateError
        )
        expect(Mirakl::Returns::OpenNewIncidentInteractor).to(
          have_received(:call).with(mirakl_order_line: order_line1)
        )
        expect(Mirakl::Returns::OpenNewIncidentInteractor).not_to(
          have_received(:call).with(mirakl_order_line: order_line2)
        )
        expect(order_line1).to have_received(:update).with(return_authorization: return_authorization)
        expect(order_line2).not_to have_received(:update).with(return_authorization: return_authorization)
      end
    end

    context 'when all Mirakl::OrderLine are in an invalid state' do
      before do
        allow(order_line1).to receive(:state).and_return('INCIDENT_OPEN')
        allow(order_line2).to receive(:state).and_return('INCIDENT_OPEN')
      end

      it 'does not open new incidents and raises an error' do
        expect { create_incident_interactor.call }.to raise_exception(
          ::Mirakl::Returns::CreateIncidentInteractor::InvalidStateError
        )
        expect(Mirakl::Returns::OpenNewIncidentInteractor).not_to have_received(:call)
        expect(order_line1).not_to have_received(:update).with(return_authorization: return_authorization)
        expect(order_line2).not_to have_received(:update).with(return_authorization: return_authorization)
      end
    end
  end

  describe '#quantity' do
    subject(:line_item_return_quantity) { create_incident_interactor.send(:quantity, line_item) }

    let(:create_incident_interactor) { described_class.new return_authorization: return_authorization }
    let(:return_authorization) { instance_double Spree::ReturnAuthorization, return_items: return_items }
    let(:return_items) { class_double Spree::ReturnItem, line_item_return_quantity: 5 }
    let(:line_item) { instance_double Spree::LineItem }

    before { line_item_return_quantity }

    it 'calls return_authorization.return_items.line_item_return_quantity' do
      expect(return_authorization.return_items).to have_received(:line_item_return_quantity).with(line_item)
    end

    it 'returns a number from line_item_return_quantity' do
      expect(line_item_return_quantity).to eq 5
    end
  end
end
