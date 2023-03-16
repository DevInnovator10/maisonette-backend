# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Narvar::UpdateOrderInteractor, narvar: true do
  include_context 'with Narvar context'

  describe '#call' do
    subject(:described_method) { described_class.call order: order }

    let(:order) { nil }

    before do
      allow(Spree::Order).to receive(:find).and_return(order)
    end

    it { expect(described_class.new).to be_a Interactor }
    it { expect(described_method).to be_failure }
    it { expect(described_method.error).to eq 'Order required' }

    context 'without a Narvar order created' do
      let(:order) { build(:completed_order_with_totals) }

      it { expect(described_method).to be_failure }
    end

    context 'with a completed order' do
      let(:order) { build(:order_ready_to_ship, :with_line_items, :narvar_updated_new) }

      context 'with a new Narvar order' do
        it { expect(described_method).to be_failure }
        it { expect(described_method.error).to eq 'Invalid Narvar Order state' }
      end

      context 'with a Narvar order created' do
        before do
          order.number = 'R00050001'
          order.narvar_order.state = :created
        end

        it 'updates an order on Narvar API', :vcr do
          expect(described_method).to be_success
          expect(described_method.narvar_order).to be_submitted
          expect(described_method.narvar_order.result_code).to eq 200
          expect(described_method.narvar_order.error_messages).to be_nil
        end
      end

      context 'with a Narvar order failed to submit' do
        before do
          order.number = 'R00050002'
          order.narvar_order.state = :failed_submission
        end

        it 'updates an order on Narvar API', :vcr do
          expect(described_method).to be_success
          expect(described_method.narvar_order).to be_submitted
          expect(described_method.narvar_order.result_code).to eq 200
          expect(described_method.narvar_order.error_messages).to be_nil
        end
      end
    end
  end
end
