# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Sale, type: :model do
  subject { build_stubbed(:sale) }

  describe 'associations' do
    it do
      is_expected.to(
        have_many(:sale_sku_configurations).class_name('Maisonette::SaleSkuConfiguration').dependent(:destroy)
      )
    end
    it { is_expected.to belong_to(:taxon).class_name('Spree::Taxon').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:percent_off) }
    it { is_expected.to validate_presence_of(:maisonette_liability) }
    it { is_expected.to validate_presence_of(:start_date) }

    it { is_expected.to validate_numericality_of(:percent_off).is_greater_than_or_equal_to(0.01) }
    it { is_expected.to validate_numericality_of(:percent_off).is_less_than_or_equal_to(0.99) }

    context 'when sale name is unique' do
      it {
        new_sale = build(:sale, name: 'Sale')
        expect(new_sale).to validate_uniqueness_of(:name).case_insensitive
      }
    end

    context 'when sale is permanent' do
      it { expect(build_stubbed(:sale, :permanent)).not_to validate_presence_of(:end_date) }
    end

    context 'when sale is not permanent' do
      it { is_expected.to validate_presence_of(:end_date) }

      it { expect(build(:sale, :permanent, end_date: nil)).to be_valid }
    end

    context 'when end_date is after start_date' do
      it { expect(build(:sale, start_date: Time.current, end_date: Time.zone.tomorrow)).to be_valid }
    end

    context 'when end_date is before start_date' do
      it { expect(build(:sale, start_date: Time.current, end_date: Time.zone.yesterday)).to be_invalid }

      it 'has errors on end date' do
        sale = build(:sale, start_date: Time.current, end_date: Time.zone.yesterday)
        sale.validate

        expect(sale.errors[:end_date]).to include('must be after start date')
      end
    end
  end

  describe 'after_commit on: create' do
    let(:taxonomy) { create(:taxonomy, name: 'Edits') }

    let(:sale) { build(:sale) }

    before { taxonomy }

    it 'creates a new taxon under the Edits taxonomy' do
      expect { sale.save }.to(change { taxonomy.taxons.count }.by(1)) # create
      expect { sale.save }.not_to(change { taxonomy.taxons.count }) # update
    end

    it 'assigns the sale name to the created taxon' do
      sale.save
      expect(sale.taxon).to have_attributes(name: sale.name)
    end
  end

  describe 'after_commit on: :update' do
    let(:taxon) { create(:taxon, name: 'Sale') }
    let(:sale) { create(:sale, taxon: taxon) }

    it 'assigns the new sale name to the associated taxon' do
      expect { sale.update(name: 'Sale 2') }.to change(taxon, :name).to('Sale 2')
    end

    it 'updates the associated taxon permalink using the new name' do
      expect { sale.update(name: 'Sale 2') }.to change(taxon, :permalink).to('sale-2')
    end
  end
end
