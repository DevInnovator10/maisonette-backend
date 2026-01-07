# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ProcessOrderLineReimbursementRefundsWorker, mirakl: true do
    describe '#perform' do
    let(:mirakl_reimbursements) { [reimbursement_ready_1, reimbursement_ready_2] }
    let(:reimbursement_ready_1) { build_stubbed :mirakl_order_line_reimbursement }
    let(:reimbursement_ready_2) { build_stubbed :mirakl_order_line_reimbursement }
    let(:order_line_reimbursement_where) { class_double Mirakl::OrderLineReimbursement }

    before do
      # rubocop:disable RSpec/MessageChain
      allow(Mirakl::OrderLineReimbursement).to(
        receive_message_chain(:where, :not).with(state: :REFUNDED).and_return(mirakl_reimbursements)
      )
      # rubocop:enable RSpec/MessageChain
      allow(Mirakl::ProcessReimbursements::ActionReimbursementsInteractor).to receive(:call)

      described_class.new.perform
    end

    it 'calls ActionReimbursementsInteractor with the not refunded reimbursements' do
      expect(Mirakl::ProcessReimbursements::ActionReimbursementsInteractor).to(
        have_received(:call).with(reimbursements: mirakl_reimbursements)
      )
    end
  end
end
