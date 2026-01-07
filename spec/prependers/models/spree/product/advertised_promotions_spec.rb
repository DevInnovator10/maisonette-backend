# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Product::AdvertisedPromotions, type: :model do
  let(:described_class) { Spree::Product }

  describe 'relations' do
    it do
      is_expected.to(
        have_many(:products_promotions)
        .class_name('Maisonette::ProductsPromotions')
        .with_foreign_key(:spree_product_id)
        .inverse_of(:product)
      )
    end

    it do
      is_expected.to(
        have_many(:advertised_promotions)
        .through(:products_promotions)
        .class_name('Spree::Promotion')
        .source(:promotion)
      )
    end
  end
end
