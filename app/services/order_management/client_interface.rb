# frozen_string_literal: true

require 'restforce'

module OrderManagement
  class ClientInterface
    def self.post_composite_for(payload, class_name: nil)
      response = perform_request('post', composite_endpoint, payload: payload)

      unless class_name.nil?
        ref_hash = response.body.dig('compositeResponse').select do |resp|
          resp['referenceId'] == class_name.constantize.reference_id
        end.last
      end

      return OpenStruct.new(response: response) if ref_hash&.body.blank? || !ref_hash.httpStatusCode.between?(200, 299)

      OpenStruct.new(response: response, order_management_ref: ref_hash.dig('body', 'id'))
    end

    def self.query_object_ids_by(external_ids, oms_object_name)
      response = perform_request('query', order_management_ref_query(external_ids, oms_object_name))
      OpenStruct.new(response: response, items: response.to_a)
    end

    def self.query_order_summary_by_original_order_id(original_order_id)
      response = perform_request('query', "SELECT Id FROM OrderSummary WHERE OriginalOrderId = '#{original_order_id}'")
      OpenStruct.new(response: response, order_summary: response.first)
    end

    def self.query_sales_order_by_spree_order_numbers(numbers)
      response = perform_request('query', sales_order_by_spree_order_numbers_query(numbers))

      mapped_orders = hash_of_number_order_management_ref(response)
      OpenStruct.new(response: response, mapped_orders_ref: mapped_orders)
    end

    def self.post_return_authorization(payload)
      response = perform_request('post', return_auth_endpoint, payload: payload)
      OpenStruct.new(response: response)
    end

    def self.post_return_item_received(payload)
      response = perform_request('post', return_item_endpoint, payload: payload)
      OpenStruct.new(response: response)
    end

    def self.api_version
      restforce.options[:api_version]
    end

    class << self
      delegate :instance_url, :upsert!, to: :restforce

      def restforce
        Restforce.new(restforce_configuration)
      end

      private

      def composite_endpoint
        "/services/data/v#{restforce.options[:api_version]}/composite"
      end

      def return_auth_endpoint
        '/services/apexrest/return/request'
      end

      def return_item_endpoint
        '/services/apexrest/return/refund'
      end

      def restforce_configuration
        {
          client_id: Maisonette::Config.fetch('salesforce.client_id'),
          client_secret: Maisonette::Config.fetch('salesforce.client_secret'),
          username: Maisonette::Config.fetch('salesforce.username'),
          password: Maisonette::Config.fetch('salesforce.password'),
          security_token: Maisonette::Config.fetch('salesforce.security_token'),
          api_version: Maisonette::Config.fetch('salesforce.api_version'),
          host: sales_force_host
        }
      end

      def sales_force_host
        'test.salesforce.com' unless Maisonette::Config.fetch('salesforce.production_mode')
      end

      def item_summary_ids(collection)
        collection.first&.dig('OrderItemSummaries') || []
      end

      def order_management_ref_query(external_ids, oms_object_name)
        "select Id, External_Id__c FROM #{oms_object_name} where " \
        "External_Id__c IN (#{single_quote_array(external_ids)})"
      end

      def sales_order_by_spree_order_numbers_query(numbers)
        "select Id, Order_Number__c FROM Order where Order_Number__c IN (#{single_quote_array(numbers)})"
      end

      def single_quote_array(elements)
        elements.map { |s| "\'#{s}\'" }.join(', ')
      end

      def perform_request(method, endpoint, payload: nil)
        Rails.logger.info(method: method, endpoint: endpoint, payload: payload, service: 'order_management')
        payload ? restforce.send(method, endpoint, payload) : restforce.send(method, endpoint)
      end

      def hash_of_number_order_management_ref(response)
        response.each_with_object({}) do |response_hash, initial_hash|
          key = response_hash['Order_Number__c']
          initial_hash[key] = response_hash['Id']
          initial_hash
        end
      end
    end
  end
end
