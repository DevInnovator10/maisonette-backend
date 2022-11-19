# frozen_string_literal: true

require 'rails_helper'
require 'rspec_api_documentation/dsl'

RSpec.resource 'Variant', type: :acceptance do
  let(:variant) { create :variant, :with_multiple_prices, :with_image }
  let(:variant_id) { variant.id }

  get '/api/variants/:variant_id' do
    example_request 'Fetching a variant' do
      expect(status).to eq 200
    end

    context 'when monograms exist' do
      let(:offer_settings) do
        create :offer_settings,
               :with_monogram_customizations,
               variant: variant,
               vendor: variant.prices.last.vendor,
               price: variant.prices.last
      end

      before do
        offer_settings
      end

      example_request 'Fetching a variant with Monogram Customization' do
        expect(json_response[:prices].last[:monogram][:monogram_customizations]).to(
          eq offer_settings.monogram_customizations
        )

        expect(json_response[:prices].last[:monogram][:display_monogram_customizations]).to(
          eq offer_settings.display_monogram_customizations
        )
      end

      context 'when color monogram is not required' do
        let(:offer_settings) do
          create :offer_settings,
                 :with_monogram_customizations,
                 monogram_customizations: {
                   'fonts' => [
                     { 'name' => 'Monogram Font 1', 'value' => 'serif' },
                     { 'name' => 'Monogram Font 1 Title', 'value' => 'Toy Soilder' },
                     { 'name' => 'Monogram Font 2', 'value' => 'Times' },
                     { 'name' => 'Monogram Font 2 Title', 'value' => 'Emerson' }
                   ],
                   'colors' => []
                 },
                 variant: variant,
                 vendor: variant.prices.last.vendor,
                 price: variant.prices.last
        end

        example_request 'Fetching a variant with Monogram Customization and color is not required' do
          expect(json_response[:prices].last[:monogram][:monogram_customizations][:colors]).to(
            eq([])
          )
          expect(json_response[:prices].last[:monogram][:display_monogram_customizations][:colors]).to(
            eq({})
          )
        end
      end
    end

    context 'when dimensions exist' do
      let(:variant) do
        create :variant,
               :with_multiple_prices,
               :with_image,
               height: 5,
               width: 2.5,
               depth: 1.2,
               weight: 2.5
      end

      example_request 'Fetching a variant with dimensions' do
        expect(json_response[:height]).to eq '5.0"'
        expect(json_response[:width]).to eq '2.5"'
        expect(json_response[:depth]).to eq '1.2"'
        expect(json_response[:weight]).to eq '2.5 lbs'
      end
    end

    context 'when dimensions do not exist' do
      let(:variant) do
        create :variant,
               :with_multiple_prices,
               :with_image,
               height: nil,
               width: nil,
               depth: nil,
               weight: nil
      end

      example_request 'Fetching a variant without dimensions' do
        expect(json_response[:height]).to be nil
        expect(json_response[:width]).to be nil
        expect(json_response[:depth]).to be nil
        expect(json_response[:weight]).to be nil
      end
    end
  end
end
