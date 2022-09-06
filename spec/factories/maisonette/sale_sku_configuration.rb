# frozen_string_literal: true

FactoryBot.define do
    factory :sale_sku_configuration, class: Maisonette::SaleSkuConfiguration do
    sale
    offer_settings
    created_by factory: :user
    updated_by factory: :user
  end
end
