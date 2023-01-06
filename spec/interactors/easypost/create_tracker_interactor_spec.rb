# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::CreateTrackerInteractor, mirakl: true do
  describe 'call' do
    let(:interactor) do
      described_class.new tracking_code: tracking_code,
                          carrier: carrier,
                          mirakl_order: mirakl_order,
                          return_authorization: return_authorization
    end
    let(:return_authorization) { nil }
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: 'M1234-A' }
    let(:tracking_code) {}
    let(:carrier) {}

    context 'when it is successful' do
      let(:easypost_tracker) { instance_double EasyPost::Tracker }

      before do
        allow(EasyPost::Tracker).to receive_messages(create: easypost_tracker)

        interactor.call
      end

      context 'when the tracking code does not exist' do
        let(:tracking_code) {}

        it 'does not create an EasyPost::Tracker' do
          expect(EasyPost::Tracker).not_to have_received(:create)
        end
      end

      context 'when the tracking code does exist' do
        let(:tracking_code) { '1234' }

        it 'creates an EasyPost::Tracker with the tracking code' do
          expect(EasyPost::Tracker).to have_received(:create).with(tracking_code: tracking_code, carrier: nil)
        end

        context 'when the carrier exist' do
          let(:carrier) { 'UPS' }

          it 'creates an EasyPost::Tracker with the tracking code and carrier' do
            expect(EasyPost::Tracker).to have_received(:create).with(tracking_code: tracking_code, carrier: carrier)
          end
        end
      end
    end

    context 'when an easypost error is thrown' do
      let(:tracking_code) { '1234' }
      let(:easypost_error) { EasyPost::Error.new(message) }
      let(:message) { 'error' }

      before do
        allow(interactor).to receive(:create_without_carrier)
        allow(EasyPost::Tracker).to receive(:create).and_raise(easypost_error)
        allow(Sentry).to receive(:capture_exception_with_message)

        interactor.call
      end

      it 'calls create_without_carrier' do
        expect(interactor).to have_received(:create_without_carrier).with(easypost_error)
      end

      context 'when error message is a duplicated error request' do
        let(:message) { EASYPOST_DATA[:ignore_codes][:in_flight_request] }
        let(:extra_context) do
          { tracking_code: tracking_code,
            carrier: carrier,
            mirakl_order: mirakl_order.logistic_order_id }
        end

        it 'does not call create_without_carrier' do
          expect(interactor).not_to have_received(:create_without_carrier).with(easypost_error)
        end
      end
    end

    context 'when it fails' do
      let(:exception) { StandardError.new 'a error' }
      let(:extra_context) do
        { tracking_code: tracking_code,
          carrier: carrier,
          return_authorization: return_authorization&.number,
          mirakl_order: mirakl_order.logistic_order_id,
          previous_exception: nil }
      end
      let(:tracking_code) { '1234' }

      let(:carrier) { 'UPS' }

      before do
        allow(EasyPost::Tracker).to receive(:create).and_raise(exception)
        allow(Sentry).to receive(:capture_exception_with_message)

        interactor.call
      end

      context 'when return auth is nil' do
        let(:message) { I18n.t('errors.easypost.trackers.unable_to_create') }
        let(:return_authorization) { nil }

        it 'calls Sentry.capture_exception_with_message with unable_to_create' do
          expect(Sentry).to have_received(:capture_exception_with_message).with(exception,
                                                                                message: message,
                                                                                extra: extra_context)
        end
      end

      context 'when return auth is not nil' do
        let(:message) { I18n.t('errors.easypost.trackers.unable_to_create_return') }
        let(:return_authorization) { create :return_authorization }

        it 'calls Sentry.capture_exception_with_message with unable_to_create_return' do
          expect(Sentry).to have_received(:capture_exception_with_message).with(exception,
                                                                                message: message,
                                                                                extra: extra_context)
        end
      end
    end
  end

  describe '#create_without_carrier' do
    subject(:create_without_carrier) { interactor.send :create_without_carrier, easypost_error }

    let(:interactor) { described_class.new tracking_code: tracking_code, carrier: carrier, mirakl_order: mirakl_order }
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: 'M1234-A' }
    let(:tracking_code) { '1234 ' }
    let(:carrier) { 'dhl' }
    let(:easypost_error) { EasyPost::Error.new('first attempt exception') }
    let(:easypost_tracker) { double EasyPost::Tracker, carrier: 'ups' } # rubocop:disable RSpec/VerifiedDoubles

    before do
      allow(interactor).to receive(:log_event)
    end

    context 'when it is successful' do
      let(:success_message) { I18n.t('errors.easypost.trackers.created_with_only_tracking_code') }
      let(:extra_context) do
        { tracking_code: tracking_code,
          incorrect_carrier: carrier,
          actual_carrier: easypost_tracker.carrier,
          mirakl_order: mirakl_order.logistic_order_id,
          previous_exception: easypost_error.message }
      end
      let(:shipment) { instance_double Spree::Shipment, update: true }

      before do
        allow(EasyPost::Tracker).to receive_messages(create: easypost_tracker)

        create_without_carrier
      end

      it 'creates an EasyPost::Tracker with the tracking code' do
        expect(EasyPost::Tracker).to have_received(:create).with(tracking_code: tracking_code)
      end

      it 'calls log_event with the success message' do
        expect(interactor).to have_received(:log_event).with(:info, "#{success_message}\n#{extra_context}")
      end
    end

    context 'when it fails' do
      let(:exception) { StandardError.new 'a error' }
      let(:extra_context) do
        { tracking_code: tracking_code,
          carrier: carrier,
          mirakl_order: mirakl_order.logistic_order_id,
          return_authorization: return_authorization&.number,
          previous_exception: easypost_error.message }
      end
      let(:mirakl_vendor_message) do
        I18n.t('mirakl.shipping_tracker_error_message', tracking_info: "#{tracking_code} - #{carrier}")
      end
      let(:mirakl_vendor_subject) { I18n.t('mirakl.shipping_tracker_message_subject') }

      before do
        allow(EasyPost::Tracker).to receive(:create).and_raise(exception)
        allow(Sentry).to receive(:capture_exception_with_message)
        allow(Mirakl::SendOperatorMessageToOrderInteractor).to receive(:call)

        create_without_carrier
      end

      context 'when return auth is nil' do
        let(:message) { I18n.t('errors.easypost.trackers.unable_to_create') }
        let(:return_authorization) { nil }

        it 'calls Sentry.capture_exception_with_message with unable_to_create' do
          expect(Sentry).to have_received(:capture_exception_with_message).with(exception,
                                                                                message: message,
                                                                                extra: extra_context)
        end
      end

      context 'when a mirakl order was passed' do
        it 'sends an operator message' do
          expect(Mirakl::SendOperatorMessageToOrderInteractor).to(
            have_received(:call).with(mirakl_order_id: mirakl_order.logistic_order_id,
                                      message: mirakl_vendor_message,
                                      subject: mirakl_vendor_subject,
                                      to_shop: true)
          )
        end
      end

      context 'when a mirakl order was not passed' do
        let(:mirakl_order) { nil }

        it 'does not send an operator message' do
          expect(Mirakl::SendOperatorMessageToOrderInteractor).not_to(
            have_received(:call)
          )
        end
      end
    end
  end
end
