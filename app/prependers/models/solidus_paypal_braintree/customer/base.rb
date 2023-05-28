# frozen_string_literal: true

module SolidusPaypalBraintree::Customer::Base
  def filled!
    update(filled: true)
  end
end
