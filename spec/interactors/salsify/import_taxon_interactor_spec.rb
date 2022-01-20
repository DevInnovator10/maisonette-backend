# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::ImportTaxonInteractor do
  describe '#call' do
    subject(:context) do
      described_class.call(
        product: product,
        row: row,
        import_product: import_product,
        variant_group_attributes: variant_group_attributes,
        different_variant_group_attributes: different_variant_group_attributes
      )
    end

    let(:row) { JSON.parse(file_fixture('salsify/valid_data.json').read).first }
    let(:import_product) { true }
    let(:different_variant_group_attributes) { false }

    context 'when there is a new taxon that is added to a mark down' do
      let(:taxonomy) { create(:taxonomy, :edit) }
      let(:product) do
        create(:product, :without_prices_on_master).tap { |prod| prod.master.update(sku: row['Parent ID']) }
      end
      let(:mark_down) { create(:mark_down) }
      let(:taxon_name) { 'A new taxon' }
      let(:variant_group_attributes) { create(:maisonette_variant_group_attributes, product_id: product.id) }

      before do
        taxonomy
        row['Edits'] = taxon_name
        context
      end

      it "doesn't require a taxon rebuild! to keep the mark down updated" do
        mark_down.included_taxons << Spree::Taxon.find_by(name: taxon_name)
        expect(mark_down.prices).to be_empty
        MarkDown::UpdateOnSaleInteractor.call(mark_down: mark_down)
        expect(mark_down.prices).to match_array(product.prices)
      end
    end

    context 'when there are existing taxons' do

      let(:taxonomy) { create(:taxonomy, name: taxonomy_name) }
      let(:variant) { create(:variant) }
      let(:product) { variant.product }
      let(:taxonomy_name) { Spree::Taxonomy::CATEGORY }
      let(:taxon_name) { "#{taxonomy_name} Foo" }
      let(:parent_taxon) { create(:taxon, parent_id: nil, taxonomy: taxonomy) }
      let(:taxon) { create(:taxon, name: taxon_name, parent_id: parent_taxon.id, taxonomy: taxonomy) }
      let(:category_taxonomy_id) { Spree::Taxonomy.find_by(name: taxonomy.name) }
      let(:variant_group_attributes) { create(:maisonette_variant_group_attributes, product_id: product.id) }

      before do
        Spree::Classification.create!(
          product_id: variant.product.id,
          taxon_id: taxon.id,
          maisonette_variant_group_attributes_id: variant_group_attributes.id
        )
      end

      context "when 'Trends' taxon (or any APPENDING_TAXONOMIES)" do
        let(:trends_taxonomy_id) { create(:taxonomy, name: taxonomy_name).id }
        let(:taxonomy_name) { Spree::Taxonomy::TRENDS }
        let(:taxon_name) { "#{taxonomy_name} Foo" }
        let(:permalink) { 'just-in/trends-foo' }
        let(:parent_taxon) { create(:taxon, name: 'Just In', parent_id: nil, taxonomy_id: trends_taxonomy_id) }
        let(:taxon) { create(:taxon, name: taxon_name, parent_id: parent_taxon.id, taxonomy_id: trends_taxonomy_id) }

        it 'appends "Trends" taxons' do
          trend_permalinks = product.taxons.where(taxonomy_id: trends_taxonomy_id)

          expected_permalinks = row['Trends'].split(';').map do |trend|
            "trends/#{trend.downcase.tr(' ', '-')}"
          end
          expected_permalinks << permalink

          expect { context }.to(change do
            trend_permalinks.reload.map(&:permalink).sort
          end.from([permalink]).to(expected_permalinks.sort))
        end
      end

      context "when taxonomy NOT an element of 'APPENDING_TAXONOMIES'" do
        let(:gender_taxonomy_id) { create(:taxonomy, name: taxonomy_name).id }
        let(:taxonomy_name) { Spree::Taxonomy::GENDER }
        let(:taxon_name) { "#{taxonomy_name} Foo" }
        let(:parent_taxon) { create(:taxon, parent_id: nil, taxonomy_id: gender_taxonomy_id) }
        let(:taxon) { create(:taxon, name: taxon_name, parent_id: parent_taxon.id, taxonomy_id: gender_taxonomy_id) }

        it 'replaces taxons' do
          gender_taxons = product.taxons.where(taxonomy_id: gender_taxonomy_id)

          gender_taxons.each do |taxon|
            expect { taxon.reload }.not_to raise_error(ActiveRecord::RecordNotFound)
          end

          expected_array = row['Gender'].split('>').map(&:strip)

          expect { context }.to(change do
            gender_taxons.reload.map(&:name).sort
          end.from([taxon_name]).to(expected_array.sort))
        end
      end

      context 'when the taxonomy is empty from salsify' do
        let(:row) do
          data = JSON.parse(file_fixture('salsify/valid_data.json').read).first
          data['Edits'] = ''
          data
        end
        let(:edits_taxonomy_id) { create(:taxonomy, name: taxonomy_name).id }
        let(:taxonomy_name) { Spree::Taxonomy::EDITS }
        let(:taxon_name) { "#{taxonomy_name} Foo" }
        let(:parent_taxon) { create(:taxon, parent_id: nil, taxonomy_id: edits_taxonomy_id) }
        let(:taxon) { create(:taxon, name: taxon_name, parent_id: parent_taxon.id, taxonomy_id: edits_taxonomy_id) }

        it 'removes the taxons' do
          edit_taxons = product.taxons.where(taxonomy_id: edits_taxonomy_id)

          expect { context }.to(change do
            edit_taxons.reload.map(&:name).sort
          end.from([taxon_name]).to([]))
        end
      end

      context 'when import_product is false' do
        let(:import_product) { false }

        it "does not modify the product's taxons" do
          expect { context }.not_to(change { product.taxons.count })
        end

        context 'when different_variant_group_attributes is true' do
          let(:different_variant_group_attributes) { true }

          it "modifies the product's taxons" do
            expect { context }.to(change { product.taxons.count })
          end
        end
      end

      context 'when we have 2 taxon names which generates the same taxon permalink' do
        let(:category_taxon) { Spree::Taxon.find_by(name: taxonomy.name) }
        let!(:home_taxon) { create(:taxon, parent: category_taxon, name: 'HOME') }

        it 'finds the existing taxon' do
          expect(home_taxon.permalink).to eq 'category/home'
          expect(row['Category']).to start_with 'Home > Bed'
          expect(context.messages).to be_nil
          bed_taxon = product.reload.taxons.find_by(name: 'Bed')
          expect(bed_taxon.parent).to eq home_taxon
        end

        context 'when navigation has taxon with same name' do
          let(:navigation) { create :taxonomy, name: 'Navigation' }
          let(:bed) do
            create :taxon, name: 'Bed', parent: navigation.root, taxonomy: navigation
          end

          context 'when rebuilding taxons' do
            let(:rebuild_taxon) { Spree::Taxon.rebuild! }

            before { create :taxon, name: 'Blankets & Quilts', parent: bed, taxonomy: navigation }

            it 'sets the taxons depth' do
              before_import = navigation.taxons.pluck(:depth)

              context

              expect(navigation.taxons.pluck(:depth)).to match_array(before_import)

              rebuild_taxon

              expect(navigation.taxons.pluck(:depth)).to match_array(before_import)
            end
          end
        end
      end
    end
  end
end
