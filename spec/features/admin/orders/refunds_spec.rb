# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Viewing and Editing Refunds', type: :feature do
  stub_authorization!

  let!(:refund_reason) { create(:refund_reason) }
  let(:new_refund_page) { Admin::Orders::Edit::NewRefundPage.new }
  let(:load_new_refund_page) { new_refund_page.load(number: order.number, payment_id: order.payments[0].id) }
  let(:order) { create :order_ready_to_ship }

  describe 'Refund default amount' do
    before { load_new_refund_page }

    it 'is set to 0.0' do
      expect(new_refund_page.amount_field.value).to eq '0.00'
    end
  end

  describe 'Adjustments' do
    let(:manual_refund_context) { instance_double('Context', success?: true) }

    before do
      allow(Spree::CreateManualRefundOrderAdjustmentInteractor).to receive(:call) { manual_refund_context }

      load_new_refund_page
      new_refund_page.amount_field.set 5.00
      new_refund_page.reason_drop_down.select(refund_reason.name)
    end

    context 'when the adjustment checkbox is set (default true)' do
      before { new_refund_page.submit_btn.click }

      it 'calls Spree::CreateManualRefundOrderAdjustmentInteractor' do
        expect(Spree::CreateManualRefundOrderAdjustmentInteractor).to have_received(:call)
      end

      context 'when interactor fails' do
        let(:manual_refund_context) { instance_double('Context', error: 'error', success?: false) }

        before { new_refund_page.submit_btn.click }

        it 'returns the interactor error' do
          expect(new_refund_page).to have_content "Refund #{manual_refund_context.error}"
        end
      end
    end

    context 'when the adjustment checkbox is not set (default true)' do
      before do
        new_refund_page.create_adjustment_checkbox.set(false)
        new_refund_page.submit_btn.click
      end

      it 'does not call Spree::CreateManualRefundOrderAdjustmentInteractor' do
        expect(Spree::CreateManualRefundOrderAdjustmentInteractor).not_to have_received(:call)
      end
    end
  end
end
