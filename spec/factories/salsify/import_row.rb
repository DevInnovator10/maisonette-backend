# frozen_string_literal: true

FactoryBot.define do
  factory :salsify_import_row, class: Salsify::ImportRow do
    state { :created }
    unique_key { generate(:sku) }
    trait :with_product do
      spree_product { build :product }
    end

    trait :from_dev_file do
      salsify_import { build :salsify_import, :with_dev_file }
      data do
        path = Rails.root.join('spec', 'fixtures', 'salsify', salsify_import.file_to_import)
        Salsify.parse_csv_file(path).first.to_h
      end
    end

    trait :from_inc_file do
      salsify_import { build :salsify_import, :with_inc_file }
      data do
        path = Rails.root.join('spec', 'fixtures', 'salsify', salsify_import.file_to_import)
        Salsify.parse_csv_file(path).first.to_h
      end
    end

    trait :completed do
      state { :completed }
    end

    trait :failed do
      state { :failed }
      messages { { error: 'unknown error' } }
    end
  end
end
