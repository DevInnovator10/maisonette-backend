# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::Commands::QueryOrderSummary, type: :model do
  describe '#process!' do
    subject(:process!) { oms_command.send(:process!) }

    let(:sales_order) { create(:sales_order, spree_order_id: order.id) }
    let(:oms_command) do
      OrderManagement::Commands::QueryOrderSummary.create(data: { spree_order_id: order.id })
    end
    let(:order) { create(:order) }

    let(:context) { instance_double(Interactor::Context, failure?: false) }

    before do
      allow(OrderManagement::FetchOrderSummaryInteractor).to receive(:call).with(
        sales_order: sales_order
      ).and_return(context)
    end

    it 'calls OrderManagement::FetchOrderSummaryInteractor' do
      process!

      expect(OrderManagement::FetchOrderSummaryInteractor).to have_received(:call).with(sales_order: sales_order)
    end

    context 'when there is a failure' do
      # rubocop:disable RSpec/VerifiedDoubles
      let(:context) do
        double(Interactor::Context, error: 'ERROR', failure?: true)
      end
      # rubocop:enable RSpec/VerifiedDoubles

      it 'raises an error' do
        expect { process! }.to raise_error(OrderManagement::OmsCommand::OmsCommandFailure, 'ERROR')
      end
    end
  end
end
