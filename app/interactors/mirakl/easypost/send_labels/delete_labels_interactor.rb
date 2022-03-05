# frozen_string_literal: true

module Mirakl
  module Easypost
    module SendLabels
      class DeleteLabelsInteractor < ApplicationInteractor
        helper_methods :mirakl_order

        def call
          response = Mirakl::RetrieveOrderDocumentsInteractor.call(mirakl_orders: [logistic_order_id])
                                                             .response
          return unless response

          JSON.parse(response)['order_documents']
              .select { |doc| doc['type'] == MIRAKL_DATA[:order][:documents][:labels] }
              .each { |label| Mirakl::DeleteOrderDocumentInteractor.call(doc_id: label['id']) }
        rescue StandardError => e
          rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        end

        private

        def logistic_order_id
          mirakl_order.logistic_order_id
        end
      end
    end
  end
end
