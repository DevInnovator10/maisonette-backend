# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Easypost::SendLabels::BuyReturnInteractor, mirakl: true do
  describe '#duplicate_easypost_order' do
    subject(:duplicate_easypost_order) { interactor.send :duplicate_easypost_order }

    let(:interactor) { described_class.new easypost_order: easypost_order }
    let(:easypost_order) do
      instance_double Easypost::Order, dup: returns_easypost_order, easypost_parcels: easypost_parcels
    end
    let(:easypost_parcels) { [instance_double(Easypost::Parcel)] }
    let(:returns_easypost_order) { instance_double Easypost::Order, :easypost_parcels= => easypost_parcels }

    before { duplicate_easypost_order }

    it 'duplicates the easypost_order' do
      expect(easypost_order).to have_received(:dup)
    end

    it 'assigns the parcels from the easypost_order to the returns_easypost_order' do
      expect(returns_easypost_order).to have_received(:easypost_parcels=).with(easypost_order.easypost_parcels)
    end

    it 'assigns context.return_easypost_order with the returns_easypost_order' do
      expect(interactor.context.return_easypost_order).to eq returns_easypost_order
    end
  end

  describe '#send_label_to_mirakl' do
    subject(:send_label_to_mirakl) { interactor.send :send_label_to_mirakl }

    let(:interactor) do
      described_class.new return_easypost_order: return_easypost_order, easypost_order: easypost_order
    end
    let(:easypost_order) { instance_double Easypost::Order, spree_shipment: spree_shipment }
    let(:return_easypost_order) do
      instance_double Easypost::Order,
                      send_label_to_mirakl: true,
                      master_easypost_shipment: easypost_shipment_object,
                      tracking_code: '1234310ASD'
    end
    let(:spree_shipment) { instance_double Spree::Shipment, mirakl_order: mirakl_order }
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: 'R123-A' }
    # rubocop:disable RSpec/VerifiedDoubles
    let(:easypost_shipment_object) { double EasyPost::Shipment, refresh: refreshed_easypost_shipment_object }
    let(:refreshed_easypost_shipment_object) { double EasyPost::Shipment, tracker: tracker }
    let(:tracker) { double EasyPost::Tracker, public_url: 'www.some_url.com' }
    # rubocop:enable RSpec/VerifiedDoubles

    before do
      allow(Mirakl::UpdateOrderReturnTrackingInteractor).to receive(:call)

      send_label_to_mirakl
    end

    it 'calls send_label_to_mirakl on return_easypost_order' do
      expect(return_easypost_order).to have_received(:send_label_to_mirakl)
    end

    it 'calls Mirakl::UpdateOrderReturnTrackingInteractor' do
      expect(Mirakl::UpdateOrderReturnTrackingInteractor).to(
        have_received(:call).with(logistic_order_id: mirakl_order.logistic_order_id,
                                  tracking_code: return_easypost_order.tracking_code,
                                  tracking_url: tracker.public_url)
      )
    end
  end

  describe '#call' do
    subject(:call) { interactor.call }

    let(:interactor) do
      described_class.new easypost_order: easypost_order, return_easypost_order: return_easypost_order
    end
    let(:spree_shipment) { instance_double Spree::Shipment, mirakl_order: mirakl_order }
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: '123-A' }

    let(:return_easypost_order) do
      instance_double Easypost::Order,
                      spree_shipment: spree_shipment,
                      buy_returns_order: true,
                      tracking_code: tracking_code
    end
    let(:easypost_order) { instance_double Easypost::Order, spree_shipment: spree_shipment }
    let(:generate_returns_label?) {}
    let(:tracking_code) { '123456789' }

    context 'when it is successful' do
      before do
        allow(interactor).to receive_messages(duplicate_easypost_order: true,
                                              send_label_to_mirakl: true,
                                              generate_returns_label?: generate_returns_label?)
        call
      end

      context 'when generate_returns_label? returns false' do
        let(:generate_returns_label?) { false }

        it 'does not call duplicate_easypost_order' do
          expect(interactor).not_to have_received(:duplicate_easypost_order)
        end
      end

      context 'when generate_returns_label? returns true' do
        let(:generate_returns_label?) { true }

        it 'calls duplicate_easypost_order' do
          expect(interactor).to have_received(:duplicate_easypost_order)
        end

        it 'calls buy_returns_order on return_easypost_order' do
          expect(return_easypost_order).to have_received(:buy_returns_order)
        end

        it 'calls send_label_to_mirakl' do
          expect(interactor).to have_received(:send_label_to_mirakl)
        end

        context 'when the tracking code does not exist' do
          let(:tracking_code) {}

          it 'does not call send_label_to_mirakl' do
            expect(interactor).not_to have_received(:send_label_to_mirakl)
          end
        end
      end
    end

    context 'when an error is thrown' do
      let(:exception) { StandardError.new 'some error' }
      let(:generate_returns_label?) { true }

      before do
        allow(interactor).to receive_messages(rescue_and_capture: false,
                                              generate_returns_label?: generate_returns_label?)
        allow(interactor).to receive(:duplicate_easypost_order).and_raise(exception)

        call
      end

      it 'does not fail the interactor' do
        expect(interactor.context).not_to be_failure
      end

      it 'calls rescue_and_capture' do
        expect(interactor).to have_received(:rescue_and_capture).with(
          exception,
          extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id }
        )
      end
    end
  end

  describe '#generate_return_labels?' do
    subject(:generate_return_labels?) { interactor.send :generate_returns_label? }

    let(:interactor) { described_class.new easypost_order: easypost_order }
    let(:easypost_order) do
      instance_double Easypost::Order,
                      persisted?: easypost_order_persisted?,
                      spree_shipment: spree_shipment,
                      easypost_parcels: easypost_parcels
    end
    let(:spree_shipment) { instance_double Spree::Shipment, mirakl_shop: mirakl_shop, mirakl_order: mirakl_order }
    let(:mirakl_shop) { instance_double Mirakl::Shop, generate_returns_label?: generate_returns_label? }
    let(:mirakl_order) { instance_double Mirakl::Order, order_lines: order_lines }
    let(:order_lines) { class_double Mirakl::OrderLine, not_canceled: not_canceled_order_lines }
    let(:not_canceled_order_lines) { [order_line_1, order_line_2] }
    let(:order_line_1) { instance_double Mirakl::OrderLine, line_item: line_item_1 }
    let(:order_line_2) { instance_double Mirakl::OrderLine, line_item: line_item_2 }
    let(:line_item_1) { instance_double Spree::LineItem, final_sale?: final_sale_1 }
    let(:line_item_2) { instance_double Spree::LineItem, final_sale?: final_sale_2 }
    let(:easypost_order_persisted?) { true }
    let(:generate_returns_label?) { true }
    let(:easypost_parcels) { [instance_double(Easypost::Parcel)] }
    let(:final_sale_1) { false }
    let(:final_sale_2) { false }

    before { generate_returns_label? }

    context 'when we are able to generate the return label' do
      let(:easypost_order_persisted?) { true }
      let(:generate_returns_label?) { true }
      let(:easypost_parcels) { [instance_double(Easypost::Parcel)] }
      let(:final_sale_1) { false }
      let(:final_sale_2) { false }

      it { is_expected.to eq true }
    end

    context 'when easypost order is not persisted' do
      let(:easypost_order_persisted?) { false }

      it { is_expected.to eq false }
    end

    context 'when the mirakl shop does not generate return labels' do
      let(:generate_returns_label?) { false }

      it { is_expected.to eq false }
    end

    context 'when there are multiple parcels' do
      let(:easypost_parcels) { [instance_double(Easypost::Parcel), instance_double(Easypost::Parcel)] }

      it { is_expected.to eq false }
    end

    context 'when at least one item is final sale' do
      let(:final_sale_2) { true }

      it { is_expected.to eq false }
    end
  end
end
