# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Shop, mirakl: true do
  it_behaves_like 'a Mirakl active record model'

  describe 'validations' do
    it { is_expected.to validate_presence_of(:shop_id) }
  end

  describe 'relations' do
    it { is_expected.to have_one(:vendor).class_name('Spree::Vendor') }
    it { is_expected.to have_many(:warehouses).class_name('Mirakl::Warehouse') }
  end

  describe '#warehouse_address' do
    let(:mirakl_shop) { build :mirakl_shop }
    let(:warehouses) { class_double Mirakl::Warehouse }
    let(:warehouse) { instance_double Mirakl::Warehouse, name: warehouse_name, address: warehouse_address }
    let(:warehouse_address) { instance_double Spree::Address }
    let(:warehouse_name) { 'warehouse-1' }

    before do
      allow(mirakl_shop).to receive_messages(warehouses: warehouses)
      allow(warehouses).to receive(:find_by).with(name: warehouse_name).and_return(warehouse)
    end

    it 'returns the mirakl warehouse' do
      expect(mirakl_shop.warehouse_address(warehouse_name)).to eq warehouse_address
    end
  end

  describe '#box_sizes' do
    subject { create(:mirakl_shop, box_sizes: %w[foo bar]).box_sizes }

    it { is_expected.to be_a Array }
  end
end
