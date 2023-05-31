# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Order, type: :model, mirakl: true do
  it_behaves_like 'a Mirakl active record model'

  describe 'validations' do
    it { is_expected.to validate_presence_of(:shipment_id) }
  end

  describe 'relations' do
    it { is_expected.to have_many(:order_lines) }
    it do
      expect(described_class.new).to(
        have_many(:order_line_reimbursements).class_name('Mirakl::OrderLineReimbursement').through(:order_lines)
      )
    end
    it { is_expected.to have_many(:log_entries).class_name('Spree::LogEntry').dependent(:destroy) }
    it { is_expected.to belong_to(:shipment).class_name('Spree::Shipment') }
    it { is_expected.to belong_to(:commercial_order).class_name('Mirakl::CommercialOrder').optional(true) }
  end

  describe 'scopes' do
    describe ':invoicing_date_last_month' do
      let!(:mirakl_order_invoicing_date_last_month_1) do
        create :mirakl_order, invoicing_date: (Time.current.beginning_of_month - 1.month)
      end
      let!(:mirakl_order_invoicing_date_last_month_2) do
        create :mirakl_order, invoicing_date: (Time.current.end_of_month - 1.month)
      end

      before do
        create :mirakl_order, invoicing_date: Time.current # Order received this month
        create :mirakl_order, invoicing_date: (Time.current - 2.months) # Order received 2 months ago
      end

      it 'returns orders that have been invoicing_date_last_month' do
        expect(Mirakl::Order.invoicing_date_last_month).to contain_exactly(mirakl_order_invoicing_date_last_month_1,
                                                                           mirakl_order_invoicing_date_last_month_2)
      end
    end

    describe ':invoicing_date_last_month_by_shop' do
      let!(:mirakl_order1) do
        create :mirakl_order, invoicing_date: (Time.current - 1.month), shipment: shipment
      end
      let(:shipment) { create :shipment, stock_location: mirakl_shop.stock_location }
      let(:mirakl_shop) { create :mirakl_shop, :with_stock_location, shop_id: shop_id }
      let(:shop_id) { 2002 }

      before do
        create :mirakl_order, invoicing_date: (Time.current - 1.month) # Order with another shop id
      end

      it 'returns orders received last month for a shop id' do
        expect(Mirakl::Order.invoicing_date_last_month_for_shop(shop_id)).to contain_exactly(mirakl_order1)
      end
    end

    describe ':invoicing_date_last_month_shop_ids' do
      let(:shipment1) { create :shipment, stock_location: mirakl_shop1.stock_location }
      let(:shipment2) { create :shipment, stock_location: mirakl_shop2.stock_location }
      let(:mirakl_shop1) { create :mirakl_shop, :with_stock_location, shop_id: shop_id1 }
      let(:shop_id1) { 2002 }
      let(:mirakl_shop2) { create :mirakl_shop, :with_stock_location, shop_id: shop_id2 }
      let(:shop_id2) { 4004 }

      before do
        create :mirakl_order, invoicing_date: (Time.current - 1.month), shipment: shipment1
        create :mirakl_order, invoicing_date: (Time.current - 1.month), shipment: shipment2
      end

      it 'returns shop ids for orders received last month' do
        expect(Mirakl::Order.invoicing_date_last_month_shop_ids).to contain_exactly([shop_id1, mirakl_shop1.id],
                                                                                    [shop_id2, mirakl_shop2.id])
      end
    end

    describe ':ready_to_be_received' do
      let(:mirakl_order1) { create :mirakl_order, shipment: shipment1, state: :SHIPPED }
      let(:shipment1) { create :shipment, tracking: 'foo' }
      let(:mirakl_order2) { create :mirakl_order, shipment: shipment2, state: :SHIPPED }
      let(:shipment2) { create :shipment, tracking: nil }
      let(:mirakl_order3) { create :mirakl_order, shipment: shipment3, state: :SHIPPING }
      let(:shipment3) { create :shipment, tracking: 'foo' }

      before do
        mirakl_order1 && mirakl_order2 && mirakl_order3
      end

      it 'returns the order in SHIPPED and with a tracking code' do
        expect(described_class.ready_to_be_received).to match_array [mirakl_order1]
      end
    end

    describe ':recently_accepted' do
      # for example: `Time.current` => Mon, 12 Oct 2020 03:33:33 EDT -04:00
      let(:valid_time1) { 3.hours.ago.beginning_of_hour } # => Mon, 12 Oct 2020 00:00:00 EDT -04:00
      let(:valid_time2) { 1.hour.ago.end_of_hour } # => Mon, 12 Oct 2020 02:59:59 EDT -04:00
      let(:invalid_time1) { 8.days.ago.end_of_hour } # => Sun, 4 Oct 020 03:59:59 EDT -04:00
      let(:invalid_time2) { Time.current.beginning_of_hour } # => Mon, 12 Oct 2020 03:00:00 EDT -04:00
      let(:mirakl_order1) { create(:mirakl_order, mirakl_payload: {}) }
      let(:mirakl_order2) { create(:mirakl_order, mirakl_payload: { 'acceptance_decision_date' => invalid_time1 }) }
      let(:mirakl_order3) { create(:mirakl_order, mirakl_payload: { 'acceptance_decision_date' => valid_time1 }) }
      let(:mirakl_order4) { create(:mirakl_order, mirakl_payload: { 'acceptance_decision_date' => valid_time2 }) }
      let(:mirakl_order5) { create(:mirakl_order, mirakl_payload: { 'acceptance_decision_date' => invalid_time2 }) }

      before do
        [mirakl_order1, mirakl_order2, mirakl_order3, mirakl_order4, mirakl_order5].each(&:waiting_debit_payment!)
      end

      it 'returns the orders with acceptance_decision_date within the accepted range' do
        expect(described_class.recently_accepted).to match_array [mirakl_order3, mirakl_order4]
      end
    end

    describe ':with_generate_bulk_document' do
      let(:mirakl_order1) { create(:mirakl_order) }
      let(:mirakl_order2) { create(:mirakl_order) }

      before do
        mirakl_order1.shipment.mirakl_shop.update(generate_bulk_document: true)
        mirakl_order2
      end

      it 'returns the orders of shops with bulk documents enabled' do
        expect(described_class.with_generate_bulk_document).to match_array [mirakl_order1]
      end
    end
  end

  describe 'after_save' do
    let(:mirakl_order) { create :mirakl_order }

    before do
      allow(Spree::Event).to receive(:fire)
      allow(mirakl_order).to receive_messages(shipping_info_previously_changed?: shipping_info_previously_changed?)

      mirakl_order.save!
    end

    context 'when shipping_info_changed is true' do
      let(:shipping_info_previously_changed?) { true }

      it 'fires a `mirakl_order_shipping_info_changed` event' do
        expect(Spree::Event).to have_received(:fire).with(
          'mirakl_order_shipping_info_changed', mirakl_order: mirakl_order
        )
      end
    end

    context 'when shipping_info_changed is false' do
      let(:shipping_info_previously_changed?) { false }

      it 'does not fire a `mirakl_order_shipping_info_changed` event' do
        expect(Spree::Event).not_to have_received(:fire).with(
          'mirakl_order_shipping_info_changed', mirakl_order: mirakl_order
        )
      end
    end
  end

  describe 'state_machine' do
    describe 'process_update!' do
      context 'when WAITING_DEBIT_PAYMENT' do
        it_behaves_like 'a mirakl order state event', 'WAITING_ACCEPTANCE', 'WAITING_DEBIT_PAYMENT'
      end

      context 'when REFUSED' do
        it_behaves_like 'a mirakl order state event', 'WAITING_ACCEPTANCE', 'REFUSED'
      end

      context 'when SHIPPING' do
        it_behaves_like 'a mirakl order state event', 'WAITING_DEBIT_PAYMENT', 'SHIPPING'
      end

      context 'when SHIPPED' do
        it_behaves_like 'a mirakl order state event', 'SHIPPING', 'SHIPPED'
      end

      context 'when RECEIVED' do
        it_behaves_like 'a mirakl order state event', 'SHIPPED', 'RECEIVED'
      end

      context 'when CLOSED' do
        it_behaves_like 'a mirakl order state event', 'SHIPPING', 'CLOSED'
      end

      context 'when a event is called for the current status' do
        subject(:process_update!) { mirakl_order.process_update!(rerun) }

        let(:rerun) { false }

        let(:mirakl_order) do
          build_stubbed :mirakl_order,
                        state: 'WAITING_DEBIT_PAYMENT',
                        mirakl_payload_order_state: 'WAITING_DEBIT_PAYMENT'
        end

        before do
          allow(mirakl_order).to receive_messages(waiting_debit_payment!: true,
                                                  update_incident_flag: true,
                                                  process_order_line_update!: nil)

          process_update!
        end

        it 'does not call the state event' do
          expect(mirakl_order).not_to have_received(:waiting_debit_payment!)
        end

        it 'does call process_order_line_update!' do
          expect(mirakl_order).to have_received(:process_order_line_update!)
        end

        context 'when rerun is true' do
          let(:rerun) { true }

          it 'does call the state event' do
            expect(mirakl_order).to have_received(:waiting_debit_payment!)
          end

          it 'does not call process_order_line_update!' do
            expect(mirakl_order).not_to have_received(:process_order_line_update!)
          end
        end
      end
    end

    context 'when waiting_debit_payment! event is triggered' do
      let(:mirakl_order) { create :mirakl_order }
      let(:acceptance_decision_date) { Time.zone.now }

      before do
        allow(Mirakl::OrderStateMachine::WaitingDebitPaymentOrganizer).to receive(:call)
      end

      it 'calls Mirakl::OrderStateMachine::WaitingDebitPaymentOrganizer' do
        expect { mirakl_order.waiting_debit_payment! }.to(change { Spree::LogEntry.count })
        expect(Mirakl::OrderStateMachine::WaitingDebitPaymentOrganizer).to have_received(:call).with(mirakl_order:
                                                                                                       mirakl_order)
      end

      it 'fills the acceptance_decision_date field from the payload' do
        mirakl_order.mirakl_payload['acceptance_decision_date'] = acceptance_decision_date.iso8601
        mirakl_order.waiting_debit_payment!
        expect(mirakl_order.acceptance_decision_date).to eq(mirakl_order.acceptance_decision_date)
      end
    end

    context 'when shipping! event is triggered' do
      let(:mirakl_order) { create :mirakl_order, state: :WAITING_DEBIT_PAYMENT }

      before do
        allow(Mirakl::OrderStateMachine::ShippingOrganizer).to receive(:call)
        allow(Spree::Event).to receive(:fire)
      end

      it 'calls Mirakl::OrderStateMachine::ShippingOrganizer' do
        expect { mirakl_order.shipping! }.to(change { Spree::LogEntry.count })
        expect(Mirakl::OrderStateMachine::ShippingOrganizer).to have_received(:call).with(mirakl_order:
                                                                                            mirakl_order)
      end

      it 'fires a `mirakl_order_state_changed` event' do
        mirakl_order.shipping!
        expect(Spree::Event).to have_received(:fire).with(
          'mirakl_order_state_changed', state: 'SHIPPING', mirakl_order: mirakl_order
        )
      end
    end

    context 'when shipped! event is triggered' do
      let(:mirakl_order) { create :mirakl_order, state: :SHIPPING }
      let(:shipped_date) { Time.zone.now }

      before do
        allow(mirakl_order).to receive_messages(shipped_date: shipped_date)
        allow(Mirakl::OrderStateMachine::ShippedOrganizer).to receive(:call)
        allow(Spree::Event).to receive(:fire)
      end

      it 'updates the invoicing_date date to the shipped_date' do
        mirakl_order.shipped!
        expect(mirakl_order.invoicing_date).to eq shipped_date
      end

      it 'calls Mirakl::OrderStateMachine::ShippedOrganizer' do
        expect { mirakl_order.shipped! }.to(change { Spree::LogEntry.count })
        expect(Mirakl::OrderStateMachine::ShippedOrganizer).to have_received(:call).with(mirakl_order:
                                                                                           mirakl_order)
      end

      it 'fires a `mirakl_order_state_changed` event' do
        mirakl_order.shipped!
        expect(Spree::Event).to have_received(:fire).with(
          'mirakl_order_state_changed', state: 'SHIPPED', mirakl_order: mirakl_order
        )
      end
    end

    context 'when refused! event is triggered' do
      let(:mirakl_order) { create :mirakl_order, state: :WAITING_ACCEPTANCE, mirakl_payload: mirakl_payload }
      let(:mirakl_payload) { { 'acceptance_decision_date' => acceptance_decision_date } }
      let(:acceptance_decision_date) { Time.now.iso8601 }

      before do
        allow(Mirakl::OrderStateMachine::RefusedOrganizer).to receive(:call)
      end

      it 'updates the invoicing_date date to the acceptance_decision_date' do
        mirakl_order.refused!
        expect(mirakl_order.invoicing_date).to eq acceptance_decision_date
      end

      it 'calls Mirakl::OrderStateMachine::RefusedOrganizer' do
        expect { mirakl_order.refused! }.to(change { Spree::LogEntry.count })
        expect(Mirakl::OrderStateMachine::RefusedOrganizer).to have_received(:call).with(mirakl_order:
                                                                                           mirakl_order)
      end
    end

    context 'when canceled! event is triggered' do
      let(:mirakl_order) { create :mirakl_order, state: :WAITING_ACCEPTANCE, mirakl_payload: mirakl_payload }
      let(:mirakl_payload) { { 'last_updated_date' => last_updated_date } }
      let(:last_updated_date) { Time.now.iso8601 }

      before do
        allow(Mirakl::OrderStateMachine::CanceledOrganizer).to receive(:call)
      end

      it 'updates the invoicing_date date to the last_updated_date' do
        mirakl_order.canceled
        expect(mirakl_order.invoicing_date).to eq last_updated_date
      end

      it 'calls Mirakl::OrderStateMachine::CanceledOrganizer' do
        expect { mirakl_order.canceled }.to(change { Spree::LogEntry.count })
        expect(Mirakl::OrderStateMachine::CanceledOrganizer).to have_received(:call).with(mirakl_order:
                                                                                            mirakl_order)
      end
    end

    context 'when closed! event is triggered' do
      let(:mirakl_order) { create :mirakl_order, state: :SHIPPED, mirakl_payload: mirakl_payload }
      let(:mirakl_payload) { { 'last_updated_date' => last_updated_date } }
      let(:last_updated_date) { Time.zone.parse('2018-11-27 06:50:55') }

      before do
        allow(Mirakl::OrderStateMachine::ClosedOrganizer).to receive(:call)
      end

      it 'updates invoicing_date with last_updated_date' do
        mirakl_order.closed
        expect(mirakl_order.invoicing_date).to eq last_updated_date
      end

      it 'calls Mirakl::OrderStateMachine::ClosedOrganizer' do
        expect { mirakl_order.closed }.to(change { Spree::LogEntry.count })
        expect(Mirakl::OrderStateMachine::ClosedOrganizer).to have_received(:call).with(mirakl_order:
                                                                                          mirakl_order)
      end
    end

    context 'when received! event is triggered' do
      let(:mirakl_order) { create :mirakl_order, state: :SHIPPED, mirakl_payload: mirakl_payload }
      let(:mirakl_payload) { { 'order_lines' => ['received_date' => received_date] } }
      let(:received_date) { Time.zone.parse('2018-11-27 06:50:55') }

      before do
        allow(Mirakl::OrderStateMachine::ReceivedOrganizer).to receive(:call)
      end

      it 'updates invoicing_date' do
        mirakl_order.received
        expect(mirakl_order.invoicing_date).to eq received_date
      end

      it 'calls Mirakl::OrderStateMachine::ReceivedOrganizer' do
        expect { mirakl_order.received }.to(change { Spree::LogEntry.count })
        expect(Mirakl::OrderStateMachine::ReceivedOrganizer).to have_received(:call).with(mirakl_order:
                                                                                            mirakl_order)
      end
    end
  end

  describe '#update_incident_flag' do
    let(:mirakl_order) { build_stubbed :mirakl_order, has_incident: incident }

    before do
      allow(mirakl_order).to receive_messages(update: true)

      mirakl_order.send :update_incident_flag
    end

    context 'when the incident flag is different from mirakl' do
      let(:incident) { true }

      it 'updates the flag' do
        expect(mirakl_order).to have_received(:update).with(incident: true)
      end
    end

    context 'when the incident flag is the same from mirakl' do
      let(:incident) { false }

      it 'does not update the flag' do
        expect(mirakl_order).not_to have_received(:update)
      end
    end
  end

  describe '#total' do
    subject { mirakl_order.total }

    let(:mirakl_order) { build_stubbed :mirakl_order }

    before do
      allow(mirakl_order).to receive_messages(subtotal: 10, shipping_cost: 100, tax_amount: 1000)
    end

    it { is_expected.to eq 1110 }
  end

  describe '#cancel_order!' do
    subject(:cancel_order!) { mirakl_order.cancel_order! }

    let(:mirakl_order) { build_stubbed :mirakl_order }

    before do
      allow(Mirakl::CancelOrderInteractor).to receive(:call!)

      cancel_order!
    end

    it 'calls Mirakl::CancelOrderInteractor' do
      expect(Mirakl::CancelOrderInteractor).to have_received(:call!).with(logistic_order_id:
                                                                            mirakl_order.logistic_order_id)
    end
  end

  describe '#can_cancel?' do
    context 'when mirakl order can be called' do
      let(:mirakl_order) { build_stubbed :mirakl_order, mirakl_payload: { can_cancel: true } }

      it 'returns true' do
        expect(mirakl_order.can_cancel?).to eq true
      end
    end

    context 'when mirakl order can not be called' do
      let(:mirakl_order) { build_stubbed :mirakl_order, mirakl_payload: { can_cancel: false } }

      it 'returns false' do
        expect(mirakl_order.can_cancel?).to eq false
      end
    end
  end

  describe '#accepted?' do
    context 'when the mirakl order has been accepted' do
      let(:mirakl_order) { build_stubbed :mirakl_order, mirakl_payload: { acceptance_decision_date: Time.current } }

      it 'returns true' do
        expect(mirakl_order.accepted?).to eq true
      end
    end

    context 'when the mirakl order has not been accepted' do
      let(:mirakl_order) { build_stubbed :mirakl_order, mirakl_payload: { acceptance_decision_date: nil } }

      it 'returns false' do
        expect(mirakl_order.accepted?).to eq false
      end
    end
  end

  describe '#subtotal' do
    let(:mirakl_order) { build_stubbed :mirakl_order, mirakl_payload: { price: 6.60 } }

    it 'returns price from mirakl_payload' do
      expect(mirakl_order.subtotal).to eq 6.60
    end
  end

  describe '#shipping_cost' do
    let(:mirakl_order) { build_stubbed :mirakl_order, mirakl_payload: { shipping_price: 5.00 } }

    it 'returns shipping_price from mirakl_payload' do
      expect(mirakl_order.shipping_cost).to eq 5.00
    end
  end

  describe 'tax_amount' do
    let(:mirakl_order) { build_stubbed :mirakl_order, mirakl_payload: mirakl_payload }
    let(:mirakl_payload) { { 'order_lines' => [order_line_cancelled, order_line_refused, order_line_shipped] } }
    let(:order_line_cancelled) { { 'order_line_state' => MIRAKL_DATA[:order][:state][:canceled], 'taxes' => [tax] } }
    let(:order_line_refused) { { 'order_line_state' => MIRAKL_DATA[:order][:state][:refused], 'taxes' => [tax] } }
    let(:order_line_shipped) { { 'order_line_state' => 'shipped', 'taxes' => [tax] } }
    let(:tax) { { 'amount' => 5.5 } }

    it 'returns tax amounts from mirakl_payload of not cancelled or refused order lines' do
      expect(mirakl_order.tax_amount).to eq 5.5
    end
  end

  describe '#total' do
    let(:mirakl_order) { build_stubbed :mirakl_order }

    before do
      allow(mirakl_order).to receive_messages(subtotal: 10,
                                              shipping_cost: 5,
                                              tax_amount: 3.33)
    end

    it 'returns subtotal + shipping_cost + tax_amount' do
      expect(mirakl_order.total).to eq 18.33
    end
  end

  describe 'acceptance_date' do
    let(:mirakl_order) { build_stubbed :mirakl_order, mirakl_payload: mirakl_payload }
    let(:mirakl_payload) { { 'acceptance_decision_date' => acceptance_date } }
    let(:acceptance_date) { '2018-11-21T09:42:34Z' }

    it 'returns the acceptance_date from the mirakl_payload' do
      expect(mirakl_order.acceptance_date).to eq Time.zone.parse(acceptance_date)
    end
  end

  describe 'shipped_date' do
    let(:mirakl_order) { build_stubbed :mirakl_order, mirakl_payload: mirakl_payload }
    let(:mirakl_payload) { { 'order_lines' => ['shipped_date' => shipped_date, 'received_date' => received_date] } }
    let(:shipped_date) { '2018-11-21T09:42:34Z' }
    let(:received_date) {}

    it 'returns a shipped_date from the order line' do
      expect(mirakl_order.shipped_date).to eq Time.zone.parse(shipped_date)
    end

    context 'when there is no shipped date' do
      let(:shipped_date) {}

      context 'when there is a received date' do
        let(:received_date) { '2020-10-27T11:45:20Z' }

        it 'returns a received_date from the order line' do
          expect(mirakl_order.shipped_date).to eq Time.zone.parse(received_date)
        end
      end

      context 'when there is no received date' do
        let(:received_date) {}

        it 'returns nil' do
          expect(mirakl_order.shipped_date).to eq nil
        end
      end
    end
  end

  describe '#compliance_fee_amount' do
    let(:mirakl_order) { build_stubbed :mirakl_order }
    let(:shipment) { instance_double Spree::Shipment, mirakl_shop: mirakl_shop }
    let(:mirakl_shop) do
      build_stubbed :mirakl_shop,
                    compliance_violation_fee: compliance_violation_fee,
                    compliance_violation_fee_type: compliance_violation_fee_type
    end
    let(:compliance_violation_fee) { 20.0 }
    let(:total) { 200.0 }

    before do
      allow(mirakl_order).to receive_messages(shipment: shipment, total: total)
    end

    context 'when the mirakl shop is absolute compliance fee type' do
      let(:compliance_violation_fee_type) { 'absolute' }

      it 'returns the mirakl shops compliance_violation_fee' do
        expect(mirakl_order.compliance_fee_amount).to eq compliance_violation_fee
      end
    end

    context 'when the mirakl shop is percentage compliance fee type' do
      let(:compliance_violation_fee_type) { 'percentage' }

      it 'returns a fee based on the total order value and compliance_violation_fee as a percentage' do
        expect(mirakl_order.compliance_fee_amount).to eq 40.0
      end

      context 'when a affected_total is passed into the method' do
        let(:affected_total) { 500.0 }

        it 'returns a fee based on the affected_total and compliance_violation_fee as a percentage' do
          expect(mirakl_order.compliance_fee_amount(affected_total: affected_total)).to eq 100.0
        end
      end
    end
  end

  describe '#ship_by' do
    let(:mirakl_order) { build_stubbed :mirakl_order, mirakl_payload: mirakl_payload }
    let(:mirakl_payload) { { 'shipping_deadline' => '2018-11-22T13:30:00Z' } }

    it 'returns a time from the shipping_deadline from the mirakl payload' do
      expect(mirakl_order.ship_by).to eq '2018-11-22T13:30:00Z'
    end
  end

  describe 'fetch_additional_field' do
    let(:mirakl_order) { build_stubbed :mirakl_order, mirakl_payload: mirakl_payload }

    context 'when the field exists' do
      let(:field) { 'foo' }
      let(:mirakl_payload) { { 'order_additional_fields' => [{ 'code' => field, 'value' => 1 }] } }

      it 'returns the value' do
        expect(mirakl_order.fetch_additional_field(field)).to eq 1
      end
    end

    context 'when the does not field exist' do
      let(:field) { 'foo' }
      let(:mirakl_payload) { { 'order_additional_fields' => [] } }

      it 'returns nil' do
        expect(mirakl_order.fetch_additional_field(field)).to eq nil
      end
    end
  end

  describe '#process_order_line_update!' do
    subject(:process_order_line_update!) { mirakl_order.process_order_line_update!(order_lines_payload) }

    let(:mirakl_order) { create :mirakl_order }
    let(:order_lines) { class_double Mirakl::OrderLine }
    let(:mirakl_order_line) { create :mirakl_order_line, order: mirakl_order }
    let(:order_lines_payload) { [order_line_payload] }
    let(:order_line_payload) do
      { 'order_line_id' => mirakl_order_line.mirakl_order_line_id, 'order_line_state' => 'SHIPPED' }
    end

    before do
      allow(mirakl_order).to receive_messages(order_lines: order_lines)
      allow(order_lines).to(
        receive(:find_by)
          .with(mirakl_order_line_id: mirakl_order_line.mirakl_order_line_id)
          .and_return(mirakl_order_line)
      )
      allow(mirakl_order_line).to receive(:process_update!)

      process_order_line_update!
    end

    it 'calls process_update! on the order line' do
      expect(mirakl_order_line).to have_received(:process_update!).with(order_line_payload)
    end
  end

  describe '#shipping_info_previously_changed?' do
    subject(:shipping_info_previously_changed?) { mirakl_order.send :shipping_info_previously_changed? }

    let(:mirakl_order) { create :mirakl_order }
    let(:attributes) { {} }

    before do
      mirakl_order.assign_attributes(attributes)
      mirakl_order.save!
    end

    context 'when there are no changes' do
      it { is_expected.to eq false }
    end

    context 'when the shipping_tracking changes' do
      let(:attributes) { { shipping_tracking: '123456789' } }

      it { is_expected.to eq true }
    end

    context 'when the shipping_carrier_code changes' do
      let(:attributes) { { shipping_carrier_code: 'UPS' } }

      it { is_expected.to eq true }
    end

    context 'when the shipping_tracking and shipping_carrier_code changes' do
      let(:attributes) { { shipping_tracking: '123456789', shipping_carrier_code: 'UPS' } }

      it { is_expected.to eq true }
    end
  end

  describe '#spree_order' do
    let(:mirakl_order) { build(:mirakl_order, mirakl_payload: mirakl_payload) }
    let(:mirakl_payload) { { 'commercial_id' => 1 } }

    before { allow(Spree::Order).to receive(:find_by!).with(number: 1) }

    it 'finds the spree order by the commerical id' do
      allow(Spree::Order).to receive(:find_by!).with(number: 1)
    end
  end
end
