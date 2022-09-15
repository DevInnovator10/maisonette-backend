# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Promotion::AdvertisedProducts, type: :model do
  let(:described_class) { Spree::Promotion }

  describe 'relations' do
    it do
      is_expected.to(
        have_many(:products_promotions)
        .class_name('Maisonette::ProductsPromotions')
        .with_foreign_key(:spree_promotion_id)
        .inverse_of(:promotion)
      )
    end

    it do
      is_expected.to(
        have_many(:advertised_products)
        .through(:products_promotions)
        .class_name('Spree::Product')
        .source(:product)
      )
    end
  end
end
