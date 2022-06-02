# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ProcessReimbursements::CreateReturnFeesInteractor, mirakl: true do
  describe '#call' do
    subject(:call) { described_class.call(new_refund_order_line_reimbursements: new_refund_order_line_reimbursements) }

    let(:new_refund_order_line_reimbursements) { [order_line_reimbursement] }
    let(:order_line_reimbursement) do
      create(:mirakl_order_line_reimbursement, :refund, order_line: order_line).tap do |olr|
        olr.return_authorization = return_authorization
        olr.save!
      end
    end

    let(:order_line) do
      mirakl_order.order_lines.first.tap do |mol|
        mol.order.shipment.mirakl_shop.shop_return_fee = vendor_fee_amount
        mol.order.shipment.mirakl_shop.save!
      end
    end

    let(:mirakl_co) { create :mirakl_commercial_order, spree_order: spree_order }
    let(:mirakl_order) { create :mirakl_order, commercial_order: mirakl_co, shipment: spree_order.shipments.first }

    let(:spree_order) { return_authorization.order }
    let(:order_completed_at) { 1.week.ago.to_s }

    let(:waive_customer_return_fee) { false }
    let(:return_authorization) do
      create(:return_authorization, fees: fees, easypost_tracker: easypost_tracker,
                                    waive_customer_return_fee: waive_customer_return_fee).tap do |ra|
        ra.order.update(completed_at: order_completed_at)
      end
    end
    let(:fees) { [] }
    let(:return_amount) { 5 }

    let(:easypost_tracker) { create(:easypost_tracker, tracking_code: 'TRACKING', status: tracker_status) }
    let(:tracker_status) { 'in_transit' }

    let(:default_store) { build(:store) }
    let(:customer_fee_enabled) { true }
    let(:customer_fee_amount) { 5 }
    let(:vendor_fee_amount) { 5 }
    let(:customer_fee_launch_date) { 2.weeks.ago.to_s }

    before do
      allow(default_store).to receive(:preferred_customer_return_fee_enabled).and_return(customer_fee_enabled)
      allow(default_store).to receive(:preferred_customer_return_fee_amount).and_return(customer_fee_amount)
      allow(default_store).to receive(:preferred_customer_return_fee_launch_date).and_return(customer_fee_launch_date)
      allow(Spree::Store).to receive(:default).and_return(default_store)

      allow(return_authorization).to receive(:amount).and_return return_amount

      allow(Maisonette::Slack).to receive(:notify)
    end

    context 'when there are no refund reimbursements to process' do
      let(:new_refund_order_line_reimbursements) { [] }

      it 'returns success' do
        expect(call).to be_success
      end

      it 'does not charge the customer' do
        expect { call }.not_to(change { Maisonette::Fee.count })
      end

      it 'does not charge the vendor' do
        expect { call }.to(not_change { order_line.reload.return_fee })
      end
    end

    context 'when there is no return authorization associated with the reimbursement' do
      let(:order_line_reimbursement) { create(:mirakl_order_line_reimbursement, :refund, order_line: order_line) }

      it 'returns success' do
        expect(call).to be_success
      end

      it 'does not charge the customer' do
        expect { call }.to(not_change { Maisonette::Fee.count })
      end

      it 'does not charge the vendor' do
        expect { call }.to(not_change { order_line.reload.return_fee })
      end
    end

    context 'when there is a return authorization with no associated easypost tracker' do
      let(:easypost_tracker) { nil }

      it 'returns success' do
        expect(call).to be_success
      end

      it 'does not charge the customer' do
        expect { call }.to(not_change { Maisonette::Fee.count })
      end

      it 'does not charge the vendor' do
        expect { call }.to(not_change { order_line.reload.return_fee })
      end
    end

    context 'when the return authorization has an unscanned easypost tracker' do
      let(:tracker_status) { 'pre_transit' }

      it 'returns success' do
        expect(call).to be_success
      end

      it 'does not charge the customer' do
        expect { call }.to(not_change { Maisonette::Fee.count })
      end

      it 'does not charge the vendor' do
        expect { call }.to(not_change { order_line.reload.return_fee })
      end
    end

    context 'when the return authorization is marked to waive return fee' do
      let(:waive_customer_return_fee) { true }

      it 'returns success' do
        expect(call).to be_success
      end

      it 'does not charge the customer' do
        expect { call }.to(not_change { Maisonette::Fee.count })
      end

      it 'charges the vendor' do
        expect { call }.to(change { order_line.reload.return_fee }.from(0).to(vendor_fee_amount))
      end
    end

    context 'when the return authorization is associated to a scanned easypost tracker' do
      it 'returns success' do
        expect(call).to be_success
      end

      it 'charges the customer' do
        expect { call }.to(change { Maisonette::Fee.count }.from(0).to(1))
        expect(Maisonette::Fee.return.first.amount).to eq(customer_fee_amount)
      end

      it 'charges the vendor' do
        expect { call }.to(change { order_line.reload.return_fee }.from(0).to(vendor_fee_amount))
      end

      context 'when the return authorization is already associated to a return fee' do
        let(:fees) { [create(:fee, :return)] }

        it 'returns success' do
          expect(call).to be_success
        end

        it 'does not charge the customer' do
          expect { call }.to(not_change { Maisonette::Fee.count })
        end

        it 'charges the vendor' do
          expect { call }.to(change { order_line.reload.return_fee }.from(0.0).to(vendor_fee_amount))
        end

        context 'when a vendor return fee has already been applied to this return authorization' do
          before { create :mirakl_order_line, return_authorization_id: return_authorization.id, return_fee: 5 }

          it 'returns success' do
            expect(call).to be_success
          end

          it 'does not charge the customer' do
            expect { call }.to(not_change { Maisonette::Fee.count })
          end

          it 'does not charge the vendor' do
            expect { call }.to(not_change { order_line.reload.return_fee })
          end
        end
      end

      context 'when the return amount is less than the return fee' do
        let(:return_amount) { 4.99 }

        it 'returns success' do
          expect(call).to be_success
        end

        it 'does not charge the customer' do
          expect { call }.to(not_change { Maisonette::Fee.count })
        end

        it 'charges the vendor' do
          expect { call }.to(change { order_line.reload.return_fee }.from(0.0).to(vendor_fee_amount))
        end

        it 'notifies slack' do
          variant = order_line_reimbursement.line_item.variant

          channel = 'order-sync-issues'
          slack_message = <<~MSG
            Unable to create customer return fee for #{spree_order.number} - #{return_authorization.number}
            The value of the returned item #{variant} is less than a customer return fee."
          MSG

          call
          expect(Maisonette::Slack).to have_received(:notify).with(channel: channel, payload: slack_message)
        end
      end

      context 'when the order is placed before the launch date' do
        let(:order_completed_at) { 3.weeks.ago.to_s }
        let(:customer_fee_launch_date) { 1.week.ago.to_s }

        it 'returns success' do
          expect(call).to be_success
        end

        it 'does not charge the customer' do
          expect { call }.to(not_change { Maisonette::Fee.count })
        end

        it 'charges the vendor' do
          expect { call }.to(change { order_line.reload.return_fee }.from(0.0).to(vendor_fee_amount))
        end
      end
    end

    context 'when the the launch date is invalid' do
      let(:customer_fee_launch_date) { '2022/22/22' }

      it 'returns success' do
        expect(call).to be_success
      end

      it 'does not charge the customer' do
        expect { call }.to(not_change { Maisonette::Fee.count })
      end

      it 'charges the vendor' do
        expect { call }.to(change { order_line.reload.return_fee }.from(0.0).to(vendor_fee_amount))
      end
    end

    context 'when the mirakl shop has no shop return fee' do
      let(:order_line) { create(:mirakl_order_line) }

      it 'returns success' do
        expect(call).to be_success
      end

      it 'charges the customer' do
        expect { call }.to change { Maisonette::Fee.return.count }.from(0).to(1)
        expect(Maisonette::Fee.return.first.amount).to eq(customer_fee_amount)
      end

      it 'does not charge the vendor' do
        expect { call }.to(not_change { order_line.reload.return_fee })
      end
    end

    context 'when customer return fee is disabled' do
      let(:customer_fee_enabled) { false }

      it 'returns success' do
        expect(call).to be_success
      end

      it 'does not charge the customer' do
        expect { call }.to(not_change { Maisonette::Fee.count })
      end

      it 'charges the vendor' do
        expect { call }.to(change { order_line.reload.return_fee }.from(0.0).to(vendor_fee_amount))
      end
    end
  end
end
