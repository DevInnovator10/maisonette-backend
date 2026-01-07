# frozen_string_literal: true

module Narvar
  class OrderDecorator < SimpleDelegator
    def order_return_with_narvar_url
      base_url = Maisonette::Config.fetch('narvar.return_url')
      "#{base_url}?order=#{number}&bzip=#{bill_address&.zipcode}&init=true"
    end

    def eligible_for_return?
      line_items.any?(&:returnable?) &&
        narvar_order&.submitted? &&
        Orders::ReturnPolicyInteractor.call(order: self).comply_with_return_policy
    end
  end
end
