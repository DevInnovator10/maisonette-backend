# frozen_string_literal: true

FactoryBot.define do
  factory :video, class: Maisonette::Video do
    attachment { Rails.root.join('spec/fixtures/files/videos/sample.mp4').open }
  end
end
