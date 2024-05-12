# frozen_string_literal: true

FactoryBot.modify do
  factory :refund_reason, class: 'Spree::RefundReason' do
    sequence(:name) { |n| "Refund for return ##{n}" }
    sequence(:mirakl_code) { |c| "REFUND_CODE#{c}" }
  end
end
