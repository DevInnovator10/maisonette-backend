# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ProcessReimbursements::Reimbursements, mirakl: true do
  let(:reimbursements) { FakeClass.new(mirakl_order_line: mirakl_order_line) }
  let(:mirakl_order_line) {}

  describe '#find_or_create_reimbursements' do
    let(:reimbursement_payload) { [{ 'id' => 1234, 'state' => 'NEW' }, { 'id' => 1235, 'state' => 'NEW' }] }
    let(:reimbursement1) { build_stubbed :mirakl_order_line_reimbursement, :refund }
    let(:reimbursement2) { build_stubbed :mirakl_order_line_reimbursement, :refund }

    before do
      allow(reimbursements).to receive(:find_or_create_reimbursement).and_return(reimbursement1, reimbursement2)

      reimbursements.send(:find_or_create_reimbursements, reimbursement_payload, 'refund')
    end

    it 'calls find_or_create_reimbursement' do
      expect(reimbursements).to have_received(:find_or_create_reimbursement).with(reimbursement_payload[0], 'refund')
      expect(reimbursements).to have_received(:find_or_create_reimbursement).with(reimbursement_payload[1], 'refund')
    end

    it 'adds the reimbursements to the context' do
      expect(reimbursements.context.reimbursements).to eq [reimbursement1, reimbursement2]
    end
  end

  describe '#find_or_create_reimbursement' do
    subject(:find_or_create_reimbursement) { reimbursements.send(:find_or_create_reimbursement, reimb, type) }

    let!(:previously_create_reimb) { create :mirakl_order_line_reimbursement, :refund }

    before do
      allow(reimbursements).to receive(:create_order_line_reimb)

      find_or_create_reimbursement
    end

    context 'when the id and type matches' do
      let(:reimb) { { 'id' => previously_create_reimb.mirakl_reimbursement_id } }
      let(:type) { previously_create_reimb.mirakl_type }

      it 'returns a previously created Mirakl::OrderLineReimbursement' do
        expect(find_or_create_reimbursement).to eq previously_create_reimb
      end

      it 'does not call create_order_line_reimb' do
        expect(reimbursements).not_to have_received(:create_order_line_reimb)
      end
    end

    context 'when only the id matches' do
      let(:reimb) { { 'id' => previously_create_reimb.mirakl_reimbursement_id } }
      let(:type) { 'cancelation' }

      it 'calls create_order_line_reimb' do
        expect(reimbursements).to have_received(:create_order_line_reimb).with(reimb, type)
      end
    end

    context 'when only the type matches' do
      let(:reimb) { { 'id' => '980' } }
      let(:type) { previously_create_reimb.mirakl_type }

      it 'calls create_order_line_reimb' do
        expect(reimbursements).to have_received(:create_order_line_reimb).with(reimb, type)
      end
    end
  end

  describe '#create_order_line_reimb' do
    subject(:create_order_line_reimb) { reimbursements.send :create_order_line_reimb, reimb_payload, type }

    let(:type) { 'refund' }
    let(:reimb_payload) do
      {
        'id' => '789',
        'quantity' => 2,
        'amount' => 10.5,
        'taxes' => taxes,
        'commission_amount' => 2.25,
        'commission_taxes' => commission_taxes,
        'shipping_amount' => 9.95,
        'shipping_taxes' => shipping_taxes,
        'reason_code' => 52
      }
    end
    let(:taxes) { ['tax' => 1.1] }
    let(:commission_taxes) { ['tax' => 1.2] }
    let(:shipping_taxes) { ['tax' => 1.3] }
    let(:mirakl_order_line) { instance_double Mirakl::OrderLine }
    let(:order_line_reimbursement) { instance_double Mirakl::OrderLineReimbursement, calculate_total: true }
    let(:inventory_units) { class_double Spree::InventoryUnit }
    let(:refund_reason) { class_double Spree::RefundReason }

    before do
      allow(Mirakl::OrderLineReimbursement).to receive_messages(new: order_line_reimbursement)
      allow(mirakl_order_line).to receive(:total_tax_amount).with(taxes).and_return(1.1)
      allow(mirakl_order_line).to receive(:total_tax_amount).with(commission_taxes).and_return(1.2)
      allow(mirakl_order_line).to receive(:total_tax_amount).with(shipping_taxes).and_return(1.3)
      allow(reimbursements).to receive(:inventory_units).with(2).and_return(inventory_units)
      allow(reimbursements).to receive_messages(fetch_refund_reason: refund_reason)

      create_order_line_reimb
    end

    it 'returns a Mirakl::OrderLineReimbursement' do
      expect(create_order_line_reimb).to eq order_line_reimbursement
    end

    it 'initializes Mirakl::OrderLineReimbursement with reimb_payload' do
      expect(Mirakl::OrderLineReimbursement).to have_received(:new).with(
        mirakl_reimbursement_id: '789',
        quantity: 2,
        refund_reason: refund_reason,
        order_line: mirakl_order_line,
        mirakl_type: 'refund',
        inventory_units: inventory_units,
        amount: 10.5,
        tax: 1.1,
        commission_amount: 2.25,
        commission_tax: 1.2,
        shipping_amount: 9.95,
        shipping_tax: 1.3
      )
    end

    it 'calls calculate_total on order_line_reimbursement' do
      expect(order_line_reimbursement).to have_received(:calculate_total)
    end

    it 'calls fetch_refund_reason with the reason code from the payload' do
      expect(reimbursements).to have_received(:fetch_refund_reason).with(reimb_payload['reason_code'])
    end
  end

  describe '#inventory_units' do
    subject(:inventory_units) { reimbursements.send :inventory_units, quantity }

    let(:mirakl_order_line) { create :mirakl_order_line }
    let(:line_item) { mirakl_order_line.line_item }
    let(:inventory_unit_1) { create :inventory_unit, line_item: line_item }
    let(:inventory_unit_2) { create :inventory_unit, line_item: line_item }
    let(:inventory_unit_3) { create :inventory_unit, line_item: line_item }

    before do
      inventory_unit_1
      inventory_unit_2
      inventory_unit_3
    end

    context 'when there are enough inventory units to refund' do
      let(:quantity) { 2 }

      it 'returns the inventory units equal to the quantity' do
        expect([inventory_unit_1, inventory_unit_2, inventory_unit_3]).to include(*inventory_units)
        expect(inventory_units.count).to eq quantity
      end
    end

    context('when it attempts to refund too many items') do
      let(:quantity) { 10 }

      it 'raises an error' do
        expect { inventory_units }.to raise_error(InsufficientInventoryUnits)
      end
    end
  end

  describe '#fetch_refund_reason' do
    subject(:fetch_refund_reason) { reimbursements.send :fetch_refund_reason, mirakl_reason_code }

    let(:mirakl_reason_code) { 131 }
    let(:refund_reason) { instance_double Spree::RefundReason, mirakl_code: mirakl_reason_code }

    context 'when mirakl refund reasons exist in spree' do
      before do
        refund_reason
        allow(reimbursements).to receive_messages(sync_refund_reasons: true)
        allow(Spree::RefundReason).to receive_messages(find_by: refund_reason)
      end

      it 'returns a refund reason' do
        expect(fetch_refund_reason).to eq(refund_reason)
        expect(Spree::RefundReason).to have_received(:find_by).with(mirakl_code: mirakl_reason_code)
        expect(reimbursements).not_to have_received(:sync_refund_reasons)
      end
    end

    context 'when mirakl refund reasons does not exist in spree' do
      before do
        allow(Mirakl::SyncReasonsInteractor).to receive(:call)
        allow(Spree::RefundReason).to receive(:find_by).and_return(nil, refund_reason)
      end

      it 'syncs the refund reasons and returns the new refund reason' do
        expect(fetch_refund_reason).to eq(refund_reason)
        expect(Mirakl::SyncReasonsInteractor).to have_received(:call)
        expect(Spree::RefundReason).to have_received(:find_by).with(mirakl_code: mirakl_reason_code).twice
      end
    end
  end
end

class FakeClass
  include ::Mirakl::ProcessReimbursements::Reimbursements
  include ::Interactor
end
