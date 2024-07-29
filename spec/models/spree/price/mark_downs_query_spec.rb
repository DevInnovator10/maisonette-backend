# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Price::MarkDownsQuery, type: :model do
  subject(:fetch_mark_downs!) { described_class.call(taxons: taxons, vendor_id: vendor_id) }

  let(:mark_down) { nil }
  let(:taxons) { [] }
  let(:vendor_id) { nil }

  before { mark_down }

  it { is_expected.to be_empty }

  describe 'taxon filters' do
    context 'when a mark_down that includes the taxon is present' do
      let(:mark_down) { create(:mark_down, included_taxons: [taxon]) }
      let(:taxon) { create(:taxon) }
      let(:taxons) { [taxon] }

      it 'returns the mark_down' do
        expect(fetch_mark_downs!).to include(mark_down)
      end
    end

    context 'when a mark_down that includes a parent taxon is present' do
      let(:mark_down) { create(:mark_down, included_taxons: [parent_taxon]) }
      let(:taxon) { create(:taxon, parent: parent_taxon) }
      let(:parent_taxon) { create(:taxon) }
      let(:taxons) { [taxon] }

      it 'returns the mark_down' do
        expect(fetch_mark_downs!).to include(mark_down)
      end
    end

    context 'when a mark_down that includes a parent taxon but excludes a taxon is present' do
      let(:mark_down) { create(:mark_down, included_taxons: [parent_taxon], excluded_taxons: [taxon]) }
      let(:taxon) { create(:taxon, parent: parent_taxon) }
      let(:parent_taxon) { create(:taxon) }
      let(:taxons) { [taxon] }

      it "doesn't return the mark_down" do
        expect(fetch_mark_downs!).not_to include(mark_down)
      end
    end
  end

  describe 'vendor filters' do
    let(:mark_down) do
      create(:mark_down,
             included_taxons: [taxon],
             included_vendors: included_vendors,
             excluded_vendors: excluded_vendors)
    end
    let(:taxon) { create(:taxon) }
    let(:taxons) { [taxon] }
    let(:included_vendors) { [] }
    let(:excluded_vendors) { [] }

    context 'when a mark_down that includes the vendor_id is present' do
      let(:vendor) { create(:vendor) }
      let(:vendor_id) { vendor.id }
      let(:included_vendors) { [vendor] }

      it 'returns the mark_down' do
        expect(fetch_mark_downs!).to include(mark_down)
      end
    end

    context 'when a mark_down that includes the vendor_id of another vendor is present' do
      let(:vendor) { create(:vendor) }
      let(:vendor_id) { vendor.id }
      let(:other_vendor) { create(:vendor) }
      let(:included_vendors) { [other_vendor] }

      it "doesn't return the mark_down" do
        expect(fetch_mark_downs!).not_to include(mark_down)
      end
    end

    context 'when a mark_down that excludes the vendor_id vendor is present' do
      let(:vendor) { create(:vendor) }
      let(:vendor_id) { vendor.id }
      let(:excluded_vendors) { [vendor] }

      it "doesn't return the mark_down" do
        expect(fetch_mark_downs!).not_to include(mark_down)
      end
    end
  end
end
