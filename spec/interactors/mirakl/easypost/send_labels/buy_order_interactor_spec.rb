# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Easypost::SendLabels::BuyOrderInteractor, mirakl: true do
  describe '#call' do
    let(:interactor) do
      described_class.new(easypost_order: easypost_order,
                          mirakl_order: mirakl_order,
                          easypost_error: easypost_error,
                          error_message: error_message,
                          easypost_exception: easypost_exception)
    end
    let(:easypost_order) do
      instance_double Easypost::Order, buy: true, assign_tracking_information: true, save: true
    end
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: 'R123-A' }
    let(:easypost_error) {}
    let(:error_message) {}
    let(:easypost_exception) {}

    before do
      allow(interactor).to receive_messages(destroy_easypost_orders: true,
                                            create_easypost_order: true,
                                            send_documents: true)
    end

    context 'when it is successful' do
      before { interactor.call }

      it 'calls destroy_easypost_orders' do
        expect(interactor).to have_received(:destroy_easypost_orders)
      end

      it 'calls create_easypost_order' do
        expect(interactor).to have_received(:create_easypost_order)
      end

      it 'buys the easypost order' do
        expect(easypost_order).to have_received(:buy)
      end

      it 'assigns tracking information on the easypost order' do
        expect(easypost_order).to have_received(:assign_tracking_information)
      end

      it 'saves the easypost order' do
        expect(easypost_order).to have_received(:save)
      end

      it 'calls send_documents' do
        expect(interactor).to have_received(:send_documents)
      end
    end

    context 'when an error is thrown' do
      let(:exception) { StandardError.new 'some error' }

      before do
        allow(interactor).to receive_messages(rescue_and_capture: false)
        allow(easypost_order).to receive(:buy).and_raise(exception)

        interactor.call
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

      it 'saves the error messages to context' do
        expect(interactor.context.error_message).to eq exception.message
      end

      context 'when the exception is a EasyPost::Error' do
        let(:exception) { EasyPost::Error.new 'some error' }

        it 'saves the EasyPost::Error to context' do
          expect(interactor.context.easypost_error).to eq exception
        end
      end
    end

    context 'when there is no easypost order' do
      let(:easypost_order) {}

      before do
        allow(interactor).to receive_messages(easypost_order: easypost_order)
        allow(Sentry).to receive(:capture_exception_with_message)

        interactor.call
      end

      it 'does not raise any errors' do
        expect(Sentry).not_to have_received(:capture_exception_with_message)
      end
    end

    context 'when there is an easypost_error' do
      let(:easypost_error) { true }

      before do
        allow(interactor).to receive_messages(easypost_order: easypost_order)
        allow(Sentry).to receive(:capture_exception_with_message)

        interactor.call
      end

      it 'does not call buy on the easypost order' do
        expect(easypost_order).not_to have_received(:buy)
      end

      it 'does not raise any errors' do
        expect(Sentry).not_to have_received(:capture_exception_with_message)
      end
    end

    context 'when there is an error_message' do
      let(:error_message) { true }

      before do
        allow(interactor).to receive_messages(easypost_order: easypost_order)
        allow(Sentry).to receive(:capture_exception_with_message)

        interactor.call
      end

      it 'does not call buy on the easypost order' do
        expect(easypost_order).not_to have_received(:buy)
      end

      it 'does not raise any errors' do
        expect(Sentry).not_to have_received(:capture_exception_with_message)
      end
    end

    context 'when there is an easypost_exception' do
      let(:easypost_exception) { true }

      before do
        allow(interactor).to receive_messages(easypost_order: easypost_order)
        allow(Sentry).to receive(:capture_exception_with_message)

        interactor.call
      end

      it 'does not call buy on the easypost order' do
        expect(easypost_order).not_to have_received(:buy)
      end

      it 'does not raise any errors' do
        expect(Sentry).not_to have_received(:capture_exception_with_message)
      end
    end
  end

  describe '#destroy_easypost_orders' do
    subject(:destroy_easypost_orders) { interactor.send :destroy_easypost_orders }

    let(:interactor) do
      described_class.new mirakl_order: mirakl_order, destroy_easypost_orders: destroy_easypost_orders_flag
    end
    let(:mirakl_order) { instance_double Mirakl::Order, shipment: shipment }
    let(:shipment) { instance_double Spree::Shipment, easypost_orders: easypost_orders }
    let(:easypost_orders) { class_double Easypost::Order, destroy_all: true }

    before { destroy_easypost_orders }

    context 'when destroy_easypost_orders is nil' do
      let(:destroy_easypost_orders_flag) {}

      it 'does not call destroy_all on the easypost_orders' do
        expect(easypost_orders).not_to have_received(:destroy_all)
      end
    end

    context 'when destroy_easypost_orders is true' do
      let(:destroy_easypost_orders_flag) { true }

      it 'does call destroy_all on the easypost_orders' do
        expect(easypost_orders).to have_received(:destroy_all)
      end
    end

    context 'when "destroy" argument is passed as true' do
      subject(:destroy_easypost_orders) { interactor.send :destroy_easypost_orders, destroy: true }

      let(:destroy_easypost_orders_flag) {}

      it 'does call destroy_all on the easypost_orders' do
        expect(easypost_orders).to have_received(:destroy_all)
      end
    end
  end

  describe '#create_easypost_order' do
    let(:interactor) { described_class.new mirakl_order: mirakl_order, easypost_order: easypost_order }
    let(:mirakl_order) { instance_double Mirakl::Order, shipment: shipment }
    let(:shipment) { instance_double Spree::Shipment, easypost_orders: easypost_orders, mirakl_shop: mirakl_shop }
    let(:mirakl_shop) { instance_double Mirakl::Shop, manage_own_shipping?: manage_own_shipping? }
    let(:easypost_orders) { class_double Easypost::Order, not_return: easypost_order }
    let(:order_level_dimensions) { [{ width: 5.6, length: 6.4, height: 2.5, weight: 3 }] }
    let(:create_easypost_order_organizer) do
      Mirakl::Easypost::CreateOrderOrganizer.new(easypost_order: newly_created_easypost_order,
                                                 easypost_exception: easypost_exception,
                                                 error_message: error_message).context
    end
    let(:newly_created_easypost_order) { instance_double Easypost::Order }
    let(:easypost_exception) {}
    let(:easypost_order) {}
    let(:error_message) {}

    before do
      allow(interactor).to receive_messages(order_level_dimensions: order_level_dimensions,
                                            destroy_easypost_orders: true)

      allow(Mirakl::Easypost::CreateOrderOrganizer).to receive_messages(call: create_easypost_order_organizer)

      interactor.send :create_easypost_order
    end

    context 'when the shop does manage their own shipping' do
      let(:manage_own_shipping?) { true }

      it 'does not call Mirakl::Easypost::CreateOrderOrganizer.call' do
        expect(Mirakl::Easypost::CreateOrderOrganizer).not_to have_received(:call)
      end
    end

    context 'when the shop does not manage their own shipping' do
      let(:manage_own_shipping?) { false }

      context 'when there is an easypost order' do
        let(:easypost_order) { instance_double Easypost::Order, parcel_sizes_valid?: parcel_sizes_valid? }
        let(:parcel_sizes_valid?) { nil }

        it 'calls parcel_sizes_valid? on the easypost order' do
          expect(easypost_order).to have_received(:parcel_sizes_valid?).with(order_level_dimensions)
        end

        context 'when the parcel sizes do not match the order level dimensions' do
          let(:parcel_sizes_valid?) { false }

          it 'destroys the current easypost labels' do
            expect(interactor).to have_received(:destroy_easypost_orders).with(destroy: true)
          end

          it 'calls Mirakl::Easypost::CreateOrderOrganizer.call' do
            expect(Mirakl::Easypost::CreateOrderOrganizer).to have_received(:call).with(mirakl_order: mirakl_order)
          end

          it 'assigns context.easypost_order with the created easypost_order' do
            expect(interactor.context.easypost_order).to eq newly_created_easypost_order
          end
        end

        context 'when the parcel sizes do match' do
          let(:parcel_sizes_valid?) { true }

          it 'does not call Mirakl::Easypost::CreateOrderOrganizer.call' do
            expect(Mirakl::Easypost::CreateOrderOrganizer).not_to have_received(:call)
          end

          it 'does not assign a new value to context.easypost_order' do
            expect(interactor.context.easypost_order).to eq easypost_order
          end
        end
      end

      context 'when there is no easypost_order' do
        let(:easypost_order) { nil }

        it 'calls Mirakl::Easypost::CreateOrderOrganizer.call' do
          expect(Mirakl::Easypost::CreateOrderOrganizer).to have_received(:call).with(mirakl_order: mirakl_order)
        end

        it 'assigns context.easypost_order with the created easypost_order' do
          expect(interactor.context.easypost_order).to eq newly_created_easypost_order
        end

        context 'when there is an easypost_exception' do
          let(:easypost_exception) { StandardError.new 'easypost_error' }

          it 'adds easypost_exception to context' do
            expect(interactor.context.easypost_exception).to eq easypost_exception
          end
        end

        context 'when there is an error_message' do
          let(:error_message) { 'Box dimensions missing' }

          it 'adds error_message to context' do
            expect(interactor.context.error_message).to eq error_message
          end
        end
      end
    end
  end

  describe '#send_documents' do
    let(:interactor) { described_class.new easypost_order: easypost_order }
    let(:easypost_order) { instance_double Easypost::Order, send_label_to_mirakl: true, send_customs_form: true }

    before { interactor.send :send_documents }

    it 'calls send_customs_form on the easypost order' do
      expect(easypost_order).to have_received(:send_customs_form)
    end

    it 'calls send_label_to_mirakl on the easypost order' do
      expect(easypost_order).to have_received(:send_label_to_mirakl)
    end
  end

  describe '#merge_context' do
    subject(:merge_context) { interactor.send :merge_context, context_to_merge }

    let(:interactor) { described_class.new(previous_context) }

    let(:previous_context) { { some_data: 'foo' } }
    let(:context_to_merge) { Interactor::Context.new(new_context: 'fii') }

    it 'merges the context' do
      expect { merge_context }.to change { interactor.context.to_h }.from(previous_context)
                                                                    .to(previous_context.merge(context_to_merge.to_h))
    end
  end
end
