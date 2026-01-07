# frozen_string_literal: true

module SolidusPaypalBraintree::Source::Reusable
  def reusable?
    query_attribute(:reusable) && super
  end
end
