# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ProcessReimbursements::CreateCustomerReturnInteractor, mirakl: true do
  describe 'hooks' do
    let(:interactor) { described_class.new }

    it 'has after_hooks' do
      expect(described_class.after_hooks).to eq [:recalculate_orders]
    end
  end

  describe '#call' do
    let(:interactor) { described_class.new reimbursements: [order_line_reimbursement_1, order_line_reimbursement_2] }
    let(:order_line_reimbursement_1) do
      instance_double Mirakl::OrderLineReimbursement,
                      order_line: order_line_1,
                      line_item: line_item_1,
                      reimbursement: reimbursement_1
    end
    let(:order_line_reimbursement_2) do
      instance_double Mirakl::OrderLineReimbursement,
                      order_line: order_line_2,
                      line_item: line_item_2,
                      reimbursement: reimbursement_2
    end
    let(:order_line_1) { instance_double Mirakl::OrderLine, return_authorization: return_authorization_1 }
    let(:order_line_2) { instance_double Mirakl::OrderLine, return_authorization: return_authorization_2 }
    let(:reimbursement_1) { instance_double Spree::Reimbursement, update: true }
    let(:reimbursement_2) { instance_double Spree::Reimbursement, update: true }
    let(:line_item_1) { instance_double Spree::LineItem, order: spree_order }
    let(:line_item_2) { instance_double Spree::LineItem, order: spree_order }
    let(:spree_order) { instance_double Spree::Order }
    let(:return_authorization_1) do
      instance_double Spree::ReturnAuthorization,
                      blank?: false,
                      customer_returns: [],
                      return_items: return_items_1,
                      stock_location: stock_location
    end
    let(:return_authorization_2) do
      instance_double Spree::ReturnAuthorization,
                      blank?: false,
                      customer_returns: [],
                      return_items: return_items_2,
                      stock_location: stock_location
    end
    let(:stock_location) { instance_double Spree::StockLocation }
    let(:customer_return_1) { instance_double Spree::CustomerReturn }
    let(:customer_return_2) { instance_double Spree::CustomerReturn }
    let(:return_items_1) { [return_item_1, return_item_2] }
    let(:return_item_1) { instance_double Spree::ReturnItem, update: true, receive: true }
    let(:return_item_2) { instance_double Spree::ReturnItem, update: true, receive: true }
    let(:return_items_2) { [return_item_3, return_item_4] }
    let(:return_item_3) { instance_double Spree::ReturnItem, update: true, receive: true }
    let(:return_item_4) { instance_double Spree::ReturnItem, update: true, receive: true }
    let(:refunded_1?) { true }
    let(:refunded_2?) { true }

    before do
      allow(Spree::CustomerReturn).to receive(:create!).and_return(customer_return_1, customer_return_2)
      allow(Spree::Reimbursement).to receive(:create!).and_return(reimbursement_1, reimbursement_2)
      allow(order_line_reimbursement_1).to receive(:state?).with(:REFUNDED).and_return(refunded_1?)
      allow(order_line_reimbursement_2).to receive(:state?).with(:REFUNDED).and_return(refunded_1?)
    end

    context 'when it is successful' do
      before do
        interactor.call
      end

      context 'when there are no customer returns on the return authorization' do
        it 'creates a Spree::CustomerReturn' do
          expect(Spree::CustomerReturn).to have_received(:create!).with(return_items: return_items_1,
                                                                        stock_location: stock_location,
                                                                        reimbursements: [reimbursement_1])
          expect(Spree::CustomerReturn).to have_received(:create!).with(return_items: return_items_2,
                                                                        stock_location: stock_location,
                                                                        reimbursements: [reimbursement_2])
        end

        it 'updates the return items with the customer return and reimbursement and receives them' do
          expect(return_items_1).to all have_received(:update).with(customer_return: customer_return_1,
                                                                    reimbursement: reimbursement_1,

                                                                    acceptance_status: :accepted)
          expect(return_items_2).to all have_received(:update).with(customer_return: customer_return_2,
                                                                    reimbursement: reimbursement_2,
                                                                    acceptance_status: :accepted)

          expect(return_items_1).to all have_received(:receive)
          expect(return_items_2).to all have_received(:receive)
        end
      end

      context 'when there are customer returns on the return authorization' do
        let(:return_authorization_1) do
          instance_double Spree::ReturnAuthorization, customer_returns: [customer_return_1]
        end
        let(:return_authorization_2) do
          instance_double Spree::ReturnAuthorization, customer_returns: [customer_return_2]
        end

        it 'does nothing' do
          expect(Spree::CustomerReturn).not_to have_received(:create!)
          expect(Spree::Reimbursement).not_to have_received(:create!)
          return_items_1.each { |return_item| expect(return_item).not_to have_received(:update) }
          return_items_2.each { |return_item| expect(return_item).not_to have_received(:update) }
        end
      end

      context 'when there is no return authorization' do
        let(:return_authorization_1) { nil }
        let(:return_authorization_2) { nil }

        it 'does nothing' do
          expect(Spree::CustomerReturn).not_to have_received(:create!)
          expect(Spree::Reimbursement).not_to have_received(:create!)
          return_items_1.each { |return_item| expect(return_item).not_to have_received(:update) }
          return_items_2.each { |return_item| expect(return_item).not_to have_received(:update) }
        end
      end

      context 'when the order line reimbursements are not yet refunded' do
        let(:refunded_1?) { false }
        let(:refunded_2?) { false }

        it 'does not create any customer returns' do
          expect(Spree::CustomerReturn).not_to have_received(:create!)
          expect(Spree::Reimbursement).not_to have_received(:create!)
          return_items_1.each { |return_item| expect(return_item).not_to have_received(:update) }
          return_items_2.each { |return_item| expect(return_item).not_to have_received(:update) }
        end
      end
    end

    context 'when it errors' do
      let(:exception) { StandardError.new 'foo' }
      let(:order_line_reimbursement_1) { build_stubbed :mirakl_order_line_reimbursement }

      before do
        allow(order_line_reimbursement_1).to receive(:order_line).and_raise(exception)
        allow(interactor).to receive(:rescue_and_capture)

        interactor.call
      end

      it 'calls rescue_and_capture' do
        expect(interactor).to(
          have_received(:rescue_and_capture).with(exception,
                                                  error_details: order_line_reimbursement_1.attributes.to_s)
        )
      end

      it 'carries on creating the other customer returns' do
        expect(Spree::CustomerReturn).to have_received(:create!).once
      end
    end
  end

  describe '#recalculate_orders' do
    let(:interactor) { described_class.new(orders: [order1, order2]) }
    let(:order1) { instance_double Spree::Order, recalculate: true }
    let(:order2) { instance_double Spree::Order, recalculate: false }

    before { interactor.send :recalculate_orders }

    it 'calls recalculate on the orders' do
      expect([order1, order2]).to all have_received(:recalculate)
    end
  end
end
