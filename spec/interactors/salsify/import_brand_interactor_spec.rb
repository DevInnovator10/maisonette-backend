# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::ImportBrandInteractor do
  describe '#call' do
    subject(:described_method) { described_class.call params }

    let(:brand_taxonomy) { create :taxonomy, :brand }
    let(:brand_taxon) { brand_taxonomy.taxons.first }
    let(:import_row) { build(:salsify_import_row, :from_dev_file) }
    let(:params) {}

    it { is_expected.to be_failure }
    it { expect(described_method.error).to start_with 'Missing import row' }

    context 'with a context row' do
      let(:params) { { row: import_row } }

      it { is_expected.to be_failure }
      it { expect(described_method.error).to start_with 'Missing brand taxonomy' }

      context 'with a brand taxonomy' do
        let(:params) { { row: import_row, brand_taxonomy: brand_taxonomy, brand_taxon: brand_taxon } }

        it { is_expected.to be_failure }
        it { expect(described_method.error).to include 'Name is blank' }
      end
    end

    context 'with the required parameters' do
      let(:csv_file) { Rails.root.join('spec', 'fixtures', 'salsify').glob('*brand_setup*01.csv').first }
      let(:row_data) { '{}' }
      let(:import_row) { build(:salsify_import_row, :from_dev_file).tap { |row| row.data = row_data } }
      let(:params) { { row: import_row, brand_taxonomy: brand_taxonomy, brand_taxon: brand_taxon } }

      it { is_expected.to be_failure }

      context 'with N or U action', :vcr do
        let(:row_data) { Salsify.parse_csv_file(csv_file).first.to_hash }

        it { is_expected.to be_success }
        it 'creates the new taxon' do
          expect { described_method }.to change {
            brand_taxon.children.count
          }.from(0).to(1)
        end

        context 'when the target taxon exists' do
          let(:taxon_data) { import_row.data }
          let(:value) { taxon_data['meta_description'] }
          let!(:taxon) do
            create :taxon, name: taxon_data['name'], meta_description: old_description,
                           taxonomy: brand_taxonomy, parent: brand_taxon, meta_data: old_meta_data
          end
          let(:old_description) { value + '!!!' }
          let(:old_meta_data) { { 'poc_owned' => ['Old tag'] } }
          let(:poc_meta_data) do
            { 'poc_owned' => ['Indigenous Founded', 'Asian American & Pacific Islander Founded'] }
          end

          it { is_expected.to be_success }
          it 'updates the target taxon' do
            expect { described_method }.to change { brand_taxon.children.count }.by(0)
            expect { taxon.reload }.to change(taxon, :meta_description).from(old_description).to(value).and(
              change(taxon, :meta_data).from(old_meta_data).to(poc_meta_data)
            )
          end

          context 'when brand name has trailing whitespace' do
            let(:taxon_data) { import_row.data }
            let!(:taxon) do
              create :taxon, name: taxon_data['name'], meta_description: old_description,
                             taxonomy: brand_taxonomy, parent: brand_taxon
            end

            before do
              taxon_data['name'] = taxon_data['name'] + ' '
            end

            it { is_expected.to be_success }
            it 'updates the target taxon' do
              expect { described_method }.to change { brand_taxon.children.count }.by(0)
              expect { taxon.reload }.to change(taxon, :meta_description).from(old_description).to(value)
            end
          end

          context 'when brand name has different capitalization' do
            let(:taxon_data) { import_row.data }
            let!(:taxon) { create :taxon, name: old_name, taxonomy: brand_taxonomy, parent: brand_taxon }
            let(:old_name) { taxon_data['name'].downcase }
            let(:new_name) { taxon_data['name'].upcase }

            before do
              taxon_data['name'] = new_name
            end

            it { is_expected.to be_success }
            it 'updates the target taxon' do
              expect { described_method }.to change { brand_taxon.children.count }.by(0)
              expect { taxon.reload }.to change(taxon, :name).from(old_name).to(new_name)
            end
          end
        end

        context 'when an error is thrown' do
          let(:taxon_data) { import_row.data }
          let!(:taxon) do
            create :taxon, name: taxon_data['name'], taxonomy: brand_taxonomy, parent: brand_taxon

          end

          before do
            taxon.update!(name: 'some_name')
          end

          it { is_expected.to be_failure }
          it { expect(described_method.error).to include 'Brand import - Action' }
        end
      end

      context 'with D action' do
        let(:csv_file) { Rails.root.join('spec', 'fixtures', 'salsify').glob('*brand_setup*02.csv').first }
        let(:row_data) { Salsify.parse_csv_file(csv_file).first.to_hash }

        it { is_expected.to be_failure }
        it { expect(described_method.error).to include 'Record not found' }

        context 'with an existing taxon to delete' do
          let(:taxon_data) { import_row.data }
          let!(:taxon) { create :taxon, name: taxon_data['name'], taxonomy: brand_taxonomy, parent: brand_taxon }

          it { is_expected.to be_success }

          it 'deletes the target taxon' do
            expect { described_method }.to change {
              Spree::Taxon.where(id: taxon.id).count
            }.from(1).to(0)
          end
        end
      end

      context 'with an invalid action' do
        let(:row_data) { Salsify.parse_csv_file(csv_file).first.to_hash }

        before { row_data['Action'] = 'Z' }

        it { is_expected.to be_failure }
        it { expect(described_method.error).to include 'Invalid action' }
      end

      context 'with an invalid image' do
        let(:row_data) { Salsify.parse_csv_file(csv_file).first.to_hash }

        before { row_data['icon_file_name'] = 'ftp' }

        it { is_expected.to be_failure }
        it { expect(described_method.error).to include 'Invalid image' }
      end

      context 'without an image' do
        let(:row_data) { Salsify.parse_csv_file(csv_file).first.to_hash }

        before { row_data['icon_file_name'] = nil }

        it { is_expected.to be_success }
      end
    end
  end
end
