# frozen_string_literal: true

FactoryBot.define do
  factory :salsify_import, class: Salsify::Import do
    state { :created }
    import_type { :products }

    trait :with_dev_file do
      file_to_import { File.basename Rails.root.join('spec', 'fixtures', 'salsify').glob('*-dev*.csv').last }
    end

    trait :with_inc_file do
      file_to_import { File.basename Rails.root.join('spec', 'fixtures', 'salsify').glob('*-inc*.csv').last }
    end

    trait :with_import_rows do
      salsify_import_rows { build_list :salsify_import_row, 10 }
    end

    trait :failed do
      state { :failed }
      messages { { error: 'unknown error' } }
    end

    trait :processing do
      state { :processing }
    end

    trait :completed do
      state { :completed }
    end

    trait :notified do
      notified_at { Time.zone.now }
    end
  end
end
