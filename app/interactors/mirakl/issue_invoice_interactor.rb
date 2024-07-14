# frozen_string_literal: true

module Mirakl
  class IssueInvoiceInteractor < ApplicationInteractor
    include Mirakl::Api

    before :use_operator_key

    def call
      put("/invoices/#{context.invoice_id}/issue")
    end
  end
end
