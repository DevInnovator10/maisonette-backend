# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order::RestartCheckoutFlow, type: :model do
    let(:described_class) { Spree::Order }

  describe '#restart_checkout_flow' do
    subject(:restart_checkout_flow) { order.restart_checkout_flow }

    let(:order) { build_stubbed :order, state: order_state, payment_state: 'paid', number: 'M1234' }
    let(:line_items) { [] }
    let(:exception) { instance_double Spree::Order::RestartCheckoutFlowInfo, set_backtrace: true }

    before do
      allow(order).to receive_messages(update_columns: true,
                                       line_items: line_items,
                                       next!: true)
      allow(Sentry).to receive_messages(capture_exception_with_message: true)
      allow(Spree::Order::RestartCheckoutFlowInfo).to receive_messages(new: exception)

      restart_checkout_flow
    end

    context 'when the order state is cart' do
      let(:order_state) { :cart }

      it 'does not update the order' do
        expect(order).not_to have_received(:update_columns)
      end

      context 'when there are line items' do
        let(:line_items) { ['li_1', ['li_2']] }

        it 'does not call next!' do
          expect(order).not_to have_received(:next!)
        end
      end

      context 'when there are no line items' do
        let(:line_items) { [] }

        it 'does not call next!' do
          expect(order).not_to have_received(:next!)
        end
      end

      it 'does not call Sentry' do
        expect(Sentry).not_to have_received(:capture_exception_with_message)
      end
    end

    context 'when the order state complete' do
      let(:order_state) { :complete }

      let(:message) do
        <<~MESSAGE
          Order Number: #{order.number}
          Order State: #{order.state}
          Payment State: #{order.payment_state}
          Line Items: #{order.line_items.count}"
        MESSAGE
      end

      it 'returns :restart_failed' do
        expect(restart_checkout_flow).to eq :restart_failed
      end

      it 'does not update the order' do
        expect(order).not_to have_received(:update_columns)
      end

      it 'creates a Spree::Order::RestartCheckoutFlowInfo exception' do
        expect(Spree::Order::RestartCheckoutFlowInfo).to have_received(:new).with(message)
        expect(exception).to have_received(:set_backtrace)
      end

      it 'does calls Sentry' do
        expect(Sentry).to have_received(:capture_exception_with_message).with(exception)
      end

      context 'when there are line items' do
        let(:line_items) { ['li_1', ['li_2']] }

        it 'does not call next!' do
          expect(order).not_to have_received(:next!)
        end
      end

      context 'when there are no line items' do
        let(:line_items) { [] }

        it 'does not call next!' do
          expect(order).not_to have_received(:next!)
        end
      end
    end

    context 'when the order state is payment', freeze_time: true do
      let(:order_state) { :payment }
      let(:line_items) { ['line_item'] }

      it 'does update the order' do
        expect(order).to have_received(:update_columns).with(state: 'cart',
                                                             updated_at: Time.current)
      end

      context 'when there are line items' do
        let(:line_items) { ['li_1', ['li_2']] }

        it 'does call next!' do
          expect(order).to have_received(:next!)
        end
      end

      context 'when there are no line items' do
        let(:line_items) { [] }

        it 'does not call next!' do
          expect(order).not_to have_received(:next!)
        end
      end

      it 'does not call Sentry' do
        expect(Sentry).not_to have_received(:capture_exception_with_message)
      end
    end
  end
end
