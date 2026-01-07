# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Easypost::CreateOrder::SaveCheapestRateInteractor, mirakl: true do
  describe 'call' do
    let(:interactor) { described_class.new easypost_order: easypost_order, mirakl_order: mirakl_order }
    let(:mirakl_order) {}
    let(:easypost_order) do
      instance_double Easypost::Order,
                      create_easypost_order: true,
                      select_cheapest_rate: true,
                      save!: true
    end

    context 'when it is successful' do
      before do
        interactor.call
      end

      it 'creates an EasyPost::Order on the easypost_order' do
        expect(easypost_order).to have_received(:create_easypost_order)
      end

      it 'selects the cheapest rate on the easypost_order' do
        expect(easypost_order).to have_received(:select_cheapest_rate)
      end

      it 'saves the easypost_order' do
        expect(easypost_order).to have_received(:save!)
      end
    end

    context 'when an error is thrown' do
      let(:exception) { StandardError.new 'foo' }
      let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: 5 }

      before do
        allow(easypost_order).to receive(:save!).and_raise(exception)
        allow(interactor).to receive_messages(log_event: nil, rescue_and_capture: nil)

        interactor.call
      end

      it 'rescues and captures the exception' do
        expect(interactor).to have_received(:rescue_and_capture).with(
          exception,
          extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id }
        )
      end

      it 'adds easypost_exception to context' do
        expect(interactor.context.easypost_exception).to eq exception
      end

      context 'when a EasyPost::Error is thrown' do
        let(:exception) { EasyPost::Error.new 'error finding rates' }

        it 'logs the event' do
          expect(interactor).to have_received(:log_event).with(
            :error,
            "#{exception.message} - #{mirakl_order.logistic_order_id}"
          )
        end

        it 'adds easypost_exception to context' do
          expect(interactor.context.easypost_exception).to eq exception
        end
      end
    end
  end
end
