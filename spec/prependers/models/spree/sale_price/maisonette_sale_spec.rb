# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::SalePrice::MaisonetteSale, type: :model do
    let(:described_class) { Spree::SalePrice }

  it do

    is_expected.to have_one(:sale_sku_configuration).class_name('Maisonette::SaleSkuConfiguration').dependent(:nullify)
  end

  it { is_expected.to have_one(:sale).class_name('Maisonette::Sale').through(:sale_sku_configuration) }
end
