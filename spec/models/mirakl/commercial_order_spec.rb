# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::CommercialOrder, type: :model, revcascade: true do
  describe 'associations' do
    it { is_expected.to(have_many(:orders)) }
    it { is_expected.to(belong_to(:spree_order).class_name('Spree::Order')) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:commercial_order_id) }
  end

  describe 'state machine' do
    let(:error_message) { { 'detail' => error_detail } }
    let(:error_detail) { 'something went wrong!' }

    before do
      allow(mirakl_commercial_order).to receive_messages(submit_to_mirakl: true, update_error_message: true)
    end

    context 'when submit event is triggered' do
      let(:mirakl_commercial_order) { create :mirakl_commercial_order }

      it 'transitions from new to submitting' do
        expect { mirakl_commercial_order.submit }
          .to(change(mirakl_commercial_order, :state)
                .from('new')
                .to('submitting'))
      end

      it 'calls #submit_to_mirakl' do
        mirakl_commercial_order.submit
        expect(mirakl_commercial_order).to have_received(:submit_to_mirakl)
      end
    end

    context 'when submitted event is triggered' do
      let(:mirakl_commercial_order) { create :mirakl_commercial_order, state: :submitting }

      it 'transitions from submitting to submitted' do
        expect { mirakl_commercial_order.submitted }
          .to(change(mirakl_commercial_order, :state)
                .from('submitting')
                .to('submitted'))
      end
    end

    context 'when orders_created event is triggered' do
      let(:mirakl_commercial_order) { create :mirakl_commercial_order, state: :submitted }

      context 'when state is :submitted' do
        it 'transitions from submitted to orders_created' do
          expect { mirakl_commercial_order.orders_created }
            .to(change(mirakl_commercial_order, :state)
                  .from('submitted')
                  .to('orders_created'))
        end
      end

      context 'when state is :failed_order_creation' do
        let(:mirakl_commercial_order) { create :mirakl_commercial_order, state: :failed_order_creation }

        it 'transitions from submitted to orders_created' do
          expect { mirakl_commercial_order.orders_created }
            .to(change(mirakl_commercial_order, :state)
                  .from('failed_order_creation')
                  .to('orders_created'))
        end
      end

      it 'calls #update_error_message' do
        mirakl_commercial_order.orders_created
        expect(mirakl_commercial_order).to have_received(:update_error_message)
      end
    end

    context 'when failed_submission event is failed_submission' do
      let(:mirakl_commercial_order) { create :mirakl_commercial_order, state: :submitting }

      it 'transitions from submitting to failed_submission' do
        expect { mirakl_commercial_order.failed_submission }
          .to(change(mirakl_commercial_order, :state)
                .from('submitting')
                .to('failed_submission'))
      end

      it 'calls #update_error_message' do
        mirakl_commercial_order.failed_submission
        expect(mirakl_commercial_order).to have_received(:update_error_message)
      end
    end

    context 'when failed_order_creation event is failed_order_creation' do
      let(:mirakl_commercial_order) { create :mirakl_commercial_order, state: :submitted }

      it 'transitions from submitting to failed_order_creation' do
        expect { mirakl_commercial_order.failed_order_creation }
          .to(change(mirakl_commercial_order, :state)
                .from('submitted')
                .to('failed_order_creation'))
      end

      it 'calls #update_error_message' do
        mirakl_commercial_order.failed_order_creation
        expect(mirakl_commercial_order).to have_received(:update_error_message)
      end
    end
  end

  describe 'submit_to_mirakl' do
    let(:mirakl_commercial_order) { build_stubbed :mirakl_commercial_order, state: state }
    let(:state) { :submitted }
    let(:context) { instance_double Interactor::Context, success?: success? }
    let(:success?) { true }
    let(:transition) { nil }

    before do
      allow(mirakl_commercial_order).to receive_messages(update_error_message: true,
                                                         failed_submission: true,
                                                         failed_order_creation: true,
                                                         save: true)
      allow(Mirakl::SubmitCommercialOrderOrganizer).to receive_messages(call: context)
      mirakl_commercial_order.send(:submit_to_mirakl, transition)
    end

    it 'calls Mirakl::SubmitCommercialOrderOrganizer.submit_order' do
      expect(Mirakl::SubmitCommercialOrderOrganizer).to(
        have_received(:call).with(commercial_order: mirakl_commercial_order, resubmit: false)
      )
    end

    it 'assigns @context with submit order response' do
      expect(mirakl_commercial_order.instance_variable_get('@context')).to eq context
    end

    context 'when resubmit is true' do
      let(:transition) { instance_double StateMachines::Transition, args: [{ resubmit: resubmit }] }
      let(:resubmit) { true }

      it 'calls Mirakl::SubmitCommercialOrderOrganizer.call with resubmit: true' do
        expect(Mirakl::SubmitCommercialOrderOrganizer).to(
          have_received(:call).with(commercial_order: mirakl_commercial_order, resubmit: true)
        )
      end
    end

    context 'when submission is successful' do
      let(:state) { :submitted }

      it 'calls #update_error_message and saves the record' do
        expect(mirakl_commercial_order).to have_received(:update_error_message)
        expect(mirakl_commercial_order).to have_received(:save)
      end
    end

    context 'when submission fails' do
      let(:state) { :failed_submission }
      let(:success?) { true }

      it 'calls #failed_submission on the order' do
        expect(mirakl_commercial_order).to have_received(:failed_submission)
      end
    end

    context 'when order creation fails' do
      let(:state) { :submitted }
      let(:success?) { false }

      it 'calls #failed_order_creation on the order' do
        expect(mirakl_commercial_order).to have_received(:failed_order_creation)
      end
    end
  end

  describe '#recreate_mirakl_orders' do
    subject(:recreate_mirakl_orders) { commercial_order.recreate_mirakl_orders }

    let(:commercial_order) do
      build_stubbed :mirakl_commercial_order, orders: mirakl_orders, error_message: commercial_order_error_message
    end
    let(:commercial_order_error_message) { nil }

    before do
      allow(commercial_order).to receive_messages(save: true)
    end

    context 'when orders are present' do
      let(:mirakl_orders) { [(build_stubbed :mirakl_order)] }
      let(:exception) { RuntimeError.new I18n.t('errors.mirakl_orders_already_present') }
      let(:error_message) do
        I18n.t('errors.commercial_order_recreate_mirakl_orders',
               class_name: commercial_order.class,
               id: commercial_order.id,
               commercial_order_id: commercial_order.commercial_order_id,
               error: exception.message)
      end

      before do
        allow(Sentry).to receive(:capture_exception_with_message)
        allow(Mirakl::CreateSubmittedOrdersInteractor).to receive(:call!)
        allow(commercial_order).to receive(:raise).and_raise(exception)

        recreate_mirakl_orders
      end

      it 'returns false' do
        expect(recreate_mirakl_orders).to eq false
      end

      it 'raises an error in sentry' do
        expect(commercial_order).to have_received(:raise).with(I18n.t('errors.mirakl_orders_already_present'))
        expect(Sentry).to have_received(:capture_exception_with_message).with(exception, message: error_message)
      end

      it 'adds the error to #error_message' do
        expect(commercial_order.error_message).to eq error_message
      end

      it 'does not call Mirakl::CreateSubmittedOrdersInteractor' do
        expect(Mirakl::CreateSubmittedOrdersInteractor).not_to have_received(:call!)
      end

      it 'saves the record' do
        expect(commercial_order).to have_received(:save)
      end
    end

    context 'when orders are not present' do
      let(:mirakl_orders) { [] }

      context 'when it is successful' do
        let(:orders_array) { ['order1' => 'order_data', 'order2' => 'order_data'] }
        let(:orders_json) { { 'orders' => orders_array }.to_json }

        before do
          allow(Mirakl::ImportOrdersInteractor).to receive_messages(call: Interactor::Context.new(orders: orders_array))
          allow(Mirakl::CreateSubmittedOrdersInteractor).to receive(:call!)

          recreate_mirakl_orders
        end

        it 'calls Mirakl::ImportOrdersInteractor' do
          expect(Mirakl::ImportOrdersInteractor).to(
            have_received(:call).with(query: "?commercial_ids=#{commercial_order.commercial_order_id}",
                                      update_orders: false)
          )
        end

        it 'calls Mirakl::CreateSubmittedOrdersInteractor' do
          expect(Mirakl::CreateSubmittedOrdersInteractor).to(
            have_received(:call!).with(mirakl_orders_response: orders_json, commercial_order: commercial_order)
          )
        end

        it 'calls saves the commercial_order' do
          expect(commercial_order).to have_received(:save)
        end

        context 'when there is an error_message present' do
          let(:commercial_order_error_message) { 'foo' }

          it 'clears the error message' do
            expect(commercial_order.error_message).to eq nil
          end

          it 'calls saves the commercial_order' do
            expect(commercial_order).to have_received(:save)
          end
        end
      end

      context 'when an error is raised' do
        let(:exception) { StandardError.new 'some error' }
        let(:error_message) do
          I18n.t('errors.commercial_order_recreate_mirakl_orders',
                 class_name: commercial_order.class,
                 id: commercial_order.id,
                 commercial_order_id: commercial_order.commercial_order_id,
                 error: exception.message)
        end

        before do
          allow(Mirakl::ImportOrdersInteractor).to receive(:call).and_raise(exception)
          allow(Sentry).to receive(:capture_exception_with_message)

          recreate_mirakl_orders
        end

        it 'returns false' do
          expect(recreate_mirakl_orders).to eq false
        end

        it 'raises an error in sentry' do
          expect(Sentry).to have_received(:capture_exception_with_message).with(exception, message: error_message)
        end

        it 'adds the error to #error_message' do
          expect(commercial_order.error_message).to eq error_message
        end

        it 'saves the record' do
          expect(commercial_order).to have_received(:save)
        end
      end
    end
  end

  describe 'update_error_message' do
    let(:mirakl_commercial_order) { build_stubbed :mirakl_commercial_order }
    let(:context) { Interactor::Context.new message: message, exception: exception }
    let(:exception) { nil }
    let(:message) { nil }

    before do
      mirakl_commercial_order.instance_variable_set('@context', context)

      mirakl_commercial_order.send :update_error_message
    end

    context 'when it is a message' do
      let(:message) { 'error_message' }

      it 'assigns the message to error_message' do
        expect(mirakl_commercial_order.error_message).to eq message
      end
    end

    context 'when it is a standard_error' do
      let(:exception) { instance_double StandardError, message: 'exception_message' }

      it 'assigns the error detail on the order' do
        expect(mirakl_commercial_order.error_message).to eq exception.message
      end
    end

    context 'when there is no error' do
      it 'clears the error message' do
        expect(mirakl_commercial_order.error_message).to eq nil
      end
    end
  end
end
