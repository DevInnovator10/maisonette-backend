# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ProcessReimbursements::CheckIfAnyReimbursementsInteractor, mirakl: true do
  describe '#call' do
    subject(:call) { described_class.call(reimbursements: reimbursements) }

    context 'when there are no reimbursements' do
      let(:reimbursements) {}

      it 'fails the interactor' do
        expect(call).to be_failure
      end
    end

    context 'when there are reimbursements' do
      let(:reimbursements) { [instance_double(Mirakl::OrderLineReimbursement)] }

      it 'does not fails the interactor' do
        expect(call).not_to be_failure
      end
    end
  end
end
