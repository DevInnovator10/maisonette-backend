# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Returns::OpenNewIncidentInteractor, mirakl: true do
  describe '#call' do
    let(:interactor) { described_class.new(mirakl_order_line: mirakl_order_line) }
    let(:incident_code) { 'too_small' }

    let(:mirakl_order) { instance_double(Mirakl::Order, logistic_order_id: 'R123-A') }
    let(:logistic_order_id) { mirakl_order.logistic_order_id }
    let(:mirakl_order_line) do
      instance_double(Mirakl::OrderLine, order: mirakl_order, mirakl_order_line_id: 'R123-A-1')
    end
    let(:mirakl_order_line_id) { mirakl_order_line.mirakl_order_line_id }
    let(:payload) { { reason_code: incident_code } }

    context 'when it is successful' do
      before do
        allow(interactor).to receive_messages(post: true,
                                              incident_reason_code: incident_code)
        interactor.call
      end

      it 'calls post on open_incident endpoint' do
        expect(interactor).to(
          have_received(:post).with("/orders/#{logistic_order_id}/lines/#{mirakl_order_line_id}/open_incident",
                                    payload: payload.to_json)
        )
      end
    end

    context 'when it errors' do
      let(:exception) { StandardError.new 'foo' }

      before do
        allow(interactor).to receive(:incident_reason_code).and_raise(exception)
        allow(interactor).to receive(:rescue_and_capture)

        interactor.call
      end

      it 'calls rescue_and_capture' do
        expect(interactor).to have_received(:rescue_and_capture).with(exception, error_details: logistic_order_id)
      end
    end
  end

  describe '#incident_reason_code' do
    subject(:incident_reason_code) { interactor.send :incident_reason_code }

    let(:interactor) { described_class.new(mirakl_order_line: mirakl_order_line) }
    let(:spree_order) { create :order_with_line_items }
    let(:mirakl_order_line) { create :mirakl_order_line, line_item: line_item }
    let(:line_item) { spree_order.line_items[0] }
    let(:return_item) do
      create :return_item, inventory_unit: line_item.inventory_units[0], return_reason: return_reason
    end
    let(:return_reason) { create :return_reason, mirakl_code: mirakl_code }
    let(:mirakl_code) { 'CODE1' }

    let(:default_incident_ra_reason) do
      create :return_reason, name: MIRAKL_DATA[:default_return_authorization_reason], mirakl_code: 'default_reason'
    end

    before do
      return_item
      default_incident_ra_reason
    end

    context 'when there is a mirakl code for the reason on the return item' do
      it 'returns the return reason mirakl code for the associated order line' do
        expect(incident_reason_code).to eq return_reason.mirakl_code
      end
    end
  end
end
