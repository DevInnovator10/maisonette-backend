# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Product::ShippingLogic, type: :model do
    let(:described_class) { Spree::Product }

  it { is_expected.not_to have_db_column(:shipping_category_id) }

  it "doesn't validate shipping_category_id" do
    fake_product = described_class.new
    fake_product.valid?
    expect(fake_product.errors.messages).not_to include :shipping_category_id
  end

  it "doesn't responds to shipping_category association methods" do
    expect(
      [
        :shipping_category,
        :build_shipping_category,
        :create_shipping_category,
        :create_shipping_category!,
        :reload_shipping_category
      ].map { |shipping_method_name| described_class.new.respond_to? shipping_method_name }
    ).to all(be_falsey)
  end

  it 'does nothing when shipping_category= is called' do
    expect { described_class.new.shipping_category = 1 }.not_to raise_error
  end
end
