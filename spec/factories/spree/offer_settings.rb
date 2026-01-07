# frozen_string_literal: true

FactoryBot.define do
  factory :offer_settings, class: 'Spree::OfferSettings' do
    variant { association :variant, :with_multiple_prices, :in_stock, stock_location: vendor&.stock_location }
    vendor_sku { FFaker::Product.letters(10) }

    with_variant_vendor
    logistics_customizations do
      {
        'ships_alone' => false,
        'ships_in_mailer' => true,
        'internal_package1' => {
          'length' => '10.0',
          'height' => '.25',
          'weight' => '0.75',
          'width' => '8.75'
        }
      }
    end

    trait :with_variant_vendor do
      transient do
        variant_vendor_index { 0 }
      end

      after(:build) do |offer_settings, evaluator|
        offer_settings.vendor ||= offer_settings.variant.vendors[evaluator.variant_vendor_index] || create(:vendor)
        offer_settings.maisonette_sku ||= "#{offer_settings.vendor.name.upcase}#{offer_settings.variant.sku}"
      end

    end

    trait :with_monogram_customizations do
      monogrammable { true }
      monogram_price { 5.50 }
      monogram_cost_price { 2.25 }
      monogram_max_text_length { 20 }

      monogram_customizations do
        {
          'fonts' => [
            { 'name' => 'Monogram Font 1', 'value' => 'serif' },
            { 'name' => 'Monogram Font 1 Title', 'value' => 'Toy Soilder' },
            { 'name' => 'Monogram Font 2', 'value' => 'Times' },
            { 'name' => 'Monogram Font 2 Title', 'value' => 'Emerson' }
          ],
          'colors' => [
            { 'name' => 'Monogram Color 1', 'value' => '#ffffff' },
            { 'name' => 'Monogram Color 1 Title', 'value' => 'White' },
            { 'name' => 'Monogram Color 2', 'value' => '#FF0000' },
            { 'name' => 'Monogram Color 2 Title', 'value' => 'Red' }
          ]
        }
      end
    end
  end
end
