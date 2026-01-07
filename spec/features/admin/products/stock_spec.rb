# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Product Stock Management', type: :feature do

    stub_authorization!

  let(:page) { Admin::Products::Stock::IndexPage.new }
  let(:product) { variant.product }
  let(:variant) { create(:variant) }
  let(:master) { product.master }
  let(:master_row_id) { "spree_variant_#{master.id}" }
  let(:variant_row_id) { "spree_variant_#{variant.id}" }

  before { page.load(slug: product.slug) }

  it 'disables fields for master variants' do
    expect { page.variant_stock_row(id: master_row_id) }.not_to raise_error
    within page.variant_stock_row(id: master_row_id) do
      expect(page.stock_location_select.disabled?).to be true
      expect(page.backorderable_checkbox.disabled?).to be true
      expect(page.count_on_hand.disabled?).to be true
      expect { page.add_stock_button }.to raise_error Capybara::ElementNotFound
    end
  end

  it 'does not disable or hide fields for non master variants' do
    within page.variant_stock_row(id: variant_row_id) do
      expect(page.stock_location_select.disabled?).to be false
      expect(page.backorderable_checkbox.disabled?).to be false
      expect(page.count_on_hand.disabled?).to be false
      expect { page.add_stock_button }.not_to raise_error
    end
  end
end
