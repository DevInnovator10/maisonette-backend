# frozen_string_literal: true

FactoryBot.define do
  factory :oms_cancellation_reason, class: OrderManagement::CancellationReason do
    name { 'Changed Mind' }
    mirakl_code { 'CHANGED_MIND' }
  end
end
