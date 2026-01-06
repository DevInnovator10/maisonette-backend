# frozen_string_literal: true

module HaveAttributesMatcher
  extend RSpec::Matchers::DSL

  matcher :have_attributes do |expected_attributes|
    match do |actual|
      actual_attributes = actual.keys.map(&:to_sym)
      expected_attributes.map(&:to_sym).all? { |attr| actual_attributes.include?(attr) }
    end
  end
end

RSpec.configure do |config|
  config.include HaveAttributesMatcher, type: :request
  config.include HaveAttributesMatcher, type: :acceptance
end
