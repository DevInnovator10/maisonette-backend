# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ProcessReimbursements::CancelationsInteractor, mirakl: true do
  describe '#call' do
    let(:interactor) { described_class.new(order_line_payload: order_line_payload, mirakl_order: mirakl_order) }
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: 'R123-A' }
    let(:context) { interactor.context }

    context 'when it is successful' do
      before do
        allow(interactor).to receive(:find_or_create_reimbursements)

        interactor.call
      end

      context 'when there is cancelations in the order_line_payload' do
        let(:order_line_payload) { { 'cancelations' => ['cancelation_data'] } }

        it 'calls find_or_create_reimbursements' do
          expect(interactor).to have_received(:find_or_create_reimbursements).with(order_line_payload['cancelations'],
                                                                                   'cancelation')
        end
      end

      context 'when there are no cancelations in the order_line_payload' do
        let(:order_line_payload) { {} }

        it 'does not call find_or_create_reimbursements' do
          expect(interactor).not_to have_received(:find_or_create_reimbursements)
        end
      end
    end

    context 'when it errors' do
      let(:exception) { StandardError.new('something went wrong') }
      let(:order_line_payload) { { 'cancelations' => ['cancelation_data'] } }

      before do
        allow(interactor).to receive(:rescue_and_capture)
        allow(interactor).to receive(:find_or_create_reimbursements).and_raise(exception)

        interactor.call
      end

      it 'rescues and captures the exception' do
        expect(interactor).to(
          have_received(:rescue_and_capture).with(exception,
                                                  extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        )
      end
    end
  end
end
