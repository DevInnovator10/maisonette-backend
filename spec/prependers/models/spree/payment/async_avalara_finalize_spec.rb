# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Payment::AsyncAvalaraFinalize, type: :model do
    let(:described_class) { Spree::Payment }

  describe '#avalara_finalzie' do
    subject(:avalara_finalize) { payment.avalara_finalize }

    let(:payment) { build_stubbed :payment }
    let(:order) { instance_double Spree::Order, number: 'R1234' }

    before do
      allow(payment).to receive_messages(order: order,
                                         avalara_tax_enabled?: avalara_tax_enabled)
      allow(Spree::AvalaraFinalizeOrderWorker).to receive(:perform_async)

      avalara_finalize
    end

    context 'when avalara_tax_enabled? is true' do
      let(:avalara_tax_enabled) { true }

      it 'calls Spree::AvalaraFinalizeOrderWorker' do
        expect(Spree::AvalaraFinalizeOrderWorker).to have_received(:perform_async).with(order.number)
      end
    end

    context 'when avalara_tax_enabled? is false' do
      let(:avalara_tax_enabled) { false }

      it 'does not call Spree::AvalaraFinalizeOrderWorker' do
        expect(Spree::AvalaraFinalizeOrderWorker).not_to have_received(:perform_async)
      end
    end
  end
end
