# frozen_string_literal: true

FactoryBot.modify do
  factory :return_reason, class: 'Spree::ReturnReason' do
    sequence(:name) { |n| "Defect ##{n}" }
    sequence(:mirakl_code) { |c| "RETURN_CODE#{c}" }
  end
end
