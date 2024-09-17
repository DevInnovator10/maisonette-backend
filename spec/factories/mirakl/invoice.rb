# frozen_string_literal: true

FactoryBot.define do
  factory :mirakl_invoice, class: Mirakl::Invoice do
    sequence(:invoice_id, '1') { |c| "some_invoice_id-#{c}" }
    association(:mirakl_shop)

    invoice_type { :INVOICE }

    trait :credit do
      invoice_type { :CREDIT }
    end

    trait :fee do
      invoice_type { :INVOICE }
    end
  end
end
