# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::ClientInterface do
  before do
    allow(Maisonette::Config).to receive(:fetch).with('salesforce.client_id').and_return('')
    allow(Maisonette::Config).to receive(:fetch).with('salesforce.client_secret').and_return('')
    allow(Maisonette::Config).to receive(:fetch).with('salesforce.username').and_return('')
    allow(Maisonette::Config).to receive(:fetch).with('salesforce.password').and_return('')
    allow(Maisonette::Config).to receive(:fetch).with('salesforce.security_token').and_return('')
    allow(Maisonette::Config).to receive(:fetch).with('salesforce.api_version').and_call_original
    allow(Maisonette::Config).to receive(:fetch).with('salesforce.production_mode').and_return(nil)
  end

  describe '.post_composite_for', :vcr do
    subject(:post_composite_for) do
      described_class.post_composite_for(payload_request, class_name: class_name)
    end

    let(:class_name) {}

    let(:payload_request) do
      JSON.parse(file_fixture('order_management/composite_payload.json').read)
    end
    let(:response_body) do
      JSON.parse file_fixture('order_management/composite_body_response.json').read
    end

    context 'when class_name param is nil' do
      context 'when successful' do
        it 'returns the response' do
          expect(post_composite_for.response.body).to match response_body
        end
      end

      context 'when something wrong' do
        let(:error_response) do
          JSON.parse file_fixture('order_management/composite_error_body_response.json').read
        end

        it 'returns the error response' do
          expect(post_composite_for.response.body).to match error_response
        end
      end
    end

    context 'when class_name param is not nil' do
      let(:class_name) { 'OrderManagement::SalesOrder' }

      context 'when successful' do
        it 'returns an order management ref' do
          expect(post_composite_for.response.body).to match response_body
          expect(post_composite_for.order_management_ref).to eq '8011b000002GV5EAAW'
        end
      end

      context 'when something wrong' do
        let(:error_response) do
          JSON.parse file_fixture('order_management/composite_error_body_response.json').read
        end

        it 'returns an object with nothing' do
          expect(post_composite_for.response.body).to match error_response
          expect(post_composite_for.order_management_ref).to be_nil
        end
      end
    end
  end

  describe '.query_object_ids_by', :vcr do
    subject(:query_object_ids_by) { described_class.query_object_ids_by(expected_external_ids, 'OrderItemSummary') }

    let(:expected_external_ids) { %w[60OjpQcm9kdWN0LzMxOTc233 60OjpQcm9kdWN0LzMxOTc234] }
    let(:expected_ids) { %w[10u1b0000004CjYAAU 10u1b0000004CjWAAU] }

    context 'when successful' do
      it 'returns an array of item ids' do
        expect(query_object_ids_by.response).to be_a Restforce::Collection
        expect(query_object_ids_by.items.map(&:External_Id__c)).to eq expected_external_ids
        expect(query_object_ids_by.items.map(&:Id)).to eq expected_ids
      end
    end

    context 'when something wrong' do
      let(:expected_external_ids) { ['123'] }

      it 'returns an empty item summaries' do
        expect(query_object_ids_by.response).to be_a Restforce::Collection
        expect(query_object_ids_by.items).to be_empty
      end
    end
  end

  describe '.query_order_summary_by_original_order_id', :vcr do
    subject(:query_order_summary_by_original_order_id) do
      described_class.query_order_summary_by_original_order_id(original_order_id)
    end

    let(:original_order_id) { '8011b000002GubnAAC' }
    let(:expected_id) { '1Os1b0000004EbdCAE' }

    context 'when successful' do
      it 'returns the order summary' do
        expect(query_order_summary_by_original_order_id.response).to be_a Restforce::Collection
        expect(query_order_summary_by_original_order_id.order_summary.Id).to eq expected_id
      end
    end

    context 'when something went wrong' do
      let(:original_order_id) { '8011b000002GubnAAB' }

      it 'returns an empty order summary' do
        expect(query_order_summary_by_original_order_id.response).to be_a Restforce::Collection
        expect(query_order_summary_by_original_order_id.order_summary).to be_nil
      end
    end
  end

  describe '.query_sales_order_by_spree_order_numbers', :vcr do
    subject(:query_sales_order_by_spree_order_numbers) do
      described_class.query_sales_order_by_spree_order_numbers(numbers)
    end

    let(:orders) { create_list :order, 2 }
    let(:numbers) { %w[M892457582 M964633763] }
    let(:mapped_response) do
      { 'M892457582' => '8011b000002GhBOAA0', 'M964633763' => '8011b000002GgeoAAC' }
    end

    context 'when successful' do
      it 'returns mapped hash of spree number and order management ref' do
        expect(query_sales_order_by_spree_order_numbers.response).to be_a Restforce::Collection
        expect(query_sales_order_by_spree_order_numbers.mapped_orders_ref).to eq mapped_response
      end
    end

    context 'when something wrong' do
      let(:numbers) { ['123'] }

      it 'returns an empty array' do
        expect(query_sales_order_by_spree_order_numbers.response).to be_a Restforce::Collection
        expect(query_sales_order_by_spree_order_numbers.mapped_orders_ref).to be_empty
      end
    end
  end

  describe '.restforce' do
    subject(:restforce) { described_class.restforce }

    let(:restforce_instance) { instance_double(Restforce::Data::Client) }

    before { allow(Restforce).to receive(:new).and_return(restforce_instance) }

    it { is_expected.to eq restforce_instance }
  end

  describe '.post_return_authorization', vcr: { record: :new_episodes } do
    subject(:post_return_authorization) do
      described_class.post_return_authorization(payload_request)
    end

    let(:payload_request) do
      JSON.parse(file_fixture('order_management/narvar_return_auth_payload.json').read)
    end

    context 'when successful' do
      it 'returns a 200 response' do
        expect(post_return_authorization.response.status).to match 200
      end
    end

    context 'when something wrong' do
      let(:payload_request) do
        JSON.parse(file_fixture('order_management/narvar_wrong_auth_payload.json').read)
      end

      it 'returns an object with nothing' do
        expect(post_return_authorization.response.status).to match 200
      end
    end
  end

  describe '.post_return_item_received', vcr: { record: :new_episodes } do
    subject(:post_return_item_received) do
      described_class.post_return_item_received(payload_request)
    end

    let(:payload_request) do
      JSON.parse(file_fixture('order_management/returned_item_received_payload.json').read)
    end

    context 'when successful' do
      it 'returns a 200 response' do
        expect(post_return_item_received.response.status).to match 200
      end
    end
  end
end
