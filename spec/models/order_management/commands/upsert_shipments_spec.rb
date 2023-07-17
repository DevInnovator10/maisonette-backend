# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::Commands::UpsertShipments, type: :model do
  describe '#process!' do
    subject(:process!) { oms_command.send(:process!) }

    let(:oms_command) do
      described_class.create(data: { mirakl_order_id: mirakl_order_id, include_items: include_items, status: status })
    end
    let(:mirakl_order_id) { 1 }
    let(:include_items) { true }
    let(:status) { 'Label Created' }

    let(:context) { instance_double(Interactor::Context, failure?: false) }

    let(:mirakl_order) { create(:mirakl_order) }

    before do
      allow(OrderManagement::UpsertShipmentsInteractor).to receive(:call).and_return(context)
      allow(Mirakl::Order).to receive(:find).with(mirakl_order_id).and_return(mirakl_order)
    end

    it 'calls OrderManagement::UpsertShipmentInteractor' do
      process!

      expect(OrderManagement::UpsertShipmentsInteractor).to(
        have_received(:call).with(mirakl_order: mirakl_order, include_items: include_items, status: status)
      )
    end

    context 'when there is a failure' do
      # rubocop:disable RSpec/VerifiedDoubles
      let(:context) { double(Interactor::Context, error: 'ERROR', payload: { 'data' => 1 }, failure?: true) }
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
