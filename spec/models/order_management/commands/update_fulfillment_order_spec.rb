# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::Commands::UpdateFulfillmentOrder, type: :model do
    describe '#process!' do
    subject(:process!) { oms_command.send(:process!) }

    let(:oms_command) do
      described_class.create(data: { mirakl_order_id: mirakl_order_id, status: status })
    end
    let(:mirakl_order_id) { '1234' }
    let(:status) { 'Assigned' }
    let(:context) { instance_double(Interactor::Context, failure?: false) }

    before do
      allow(OrderManagement::UpdateFulfillmentOrderInteractor).to receive(:call).and_return(context)
    end

    it 'calls OrderManagement::UpdateFulfillmentOrderInteractor' do
      process!

      expect(OrderManagement::UpdateFulfillmentOrderInteractor).to(
        have_received(:call).with(mirakl_order_id: mirakl_order_id, status: status)
      )
    end

    context 'when there is a failure' do
      # rubocop:disable RSpec/VerifiedDoubles
      let(:context) { double(Interactor::Context, error: 'ERROR', payload: { 'Status' => status }, failure?: true) }
      # rubocop:enable RSpec/VerifiedDoubles

      it 'raises an error' do
        expect { process! }.to raise_error do |error|
          expect(error).to be_a(OrderManagement::OmsCommand::OmsCommandFailure)
          expect(error).to have_attributes(message: 'ERROR', payload: context.payload)
        end
      end
    end
  end
end
