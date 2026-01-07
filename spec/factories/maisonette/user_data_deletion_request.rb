# frozen_string_literal: true

FactoryBot.define do
  factory :user_data_deletion_request, class: Maisonette::UserDataDeletionRequest do
    email { user&.email || FFaker::Internet.email }
    status { 1 }
    association :user
  end
end
