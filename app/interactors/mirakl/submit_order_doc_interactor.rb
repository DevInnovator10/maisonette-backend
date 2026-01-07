# frozen_string_literal: true

module Mirakl
  class SubmitOrderDocInteractor < ApplicationInteractor
    include Mirakl::Api

    before :use_operator_key

    def call
      return unless context.binary_file

      post("/orders/#{logistic_order_id}/documents", payload: payload)
    rescue StandardError => e
      rescue_and_capture(e, extra: { mirakl_logistic_order_id: logistic_order_id })
      context.fail!(message: e.message)
    end

    private

    def payload
      { files: context.binary_file,
        order_documents: order_documents }

    end

    def order_documents
      <<~XML
        <body>
          <order_documents>
            <order_document>
              <file_name>#{context.binary_file.path}</file_name>
              <type_code>#{context.doc_type.upcase}</type_code>
            </order_document>
          </order_documents>
         </body>
      XML
    end

    def logistic_order_id
      @logistic_order_id ||= (context.logistic_order_id || context.mirakl_order.logistic_order_id)
    end
  end
end
