# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order::AllowCancel, type: :model do
  let(:described_class) { Spree::Order }

  describe '#allow_cancel?' do
    subject(:allow_cancel?) { spree_order.allow_cancel? }

    let(:spree_order) { build :order }

    context 'when a spree order is eligible for cancel according to spree' do
      before do
        allow(spree_order).to receive_messages(mirakl_commercial_order: mirakl_commercial_order,
                                               completed?: true,
                                               state: 'complete',
                                               shipment_state: nil)
      end

      context 'when there is a mirakl commercial order' do
        let(:mirakl_commercial_order) { instance_double Mirakl::CommercialOrder }

        it 'returns false' do
          expect(allow_cancel?).to eq false
        end
      end

      context 'when there is no mirakl commercial' do
        let(:mirakl_commercial_order) {}

        it 'returns true' do
          expect(allow_cancel?).to eq true
        end
      end
    end
  end
end
