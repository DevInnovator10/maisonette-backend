# frozen_string_literal: true

FactoryBot.define do

  factory :kustomer_order, class: Maisonette::Kustomer::Order do
    kustomerable { create(:order) }
  end
end
