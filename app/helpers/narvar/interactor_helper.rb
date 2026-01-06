# frozen_string_literal: true

module Narvar
  module InteractorHelper
    private

    def check_errors(result, create:)
      if result.code == 200
        create ? narvar_order.created! : narvar_order.submitted!
        nil
      else
        create ? narvar_order.failed_create! : narvar_order.failed!
        result.body
      end
    end
  end
end
