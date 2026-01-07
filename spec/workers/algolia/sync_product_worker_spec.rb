# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Algolia::SyncProductWorker do
  describe '#perform' do
    subject(:perform) { described_class.new.perform(algolia_product_id, remove_boolean) }

    let(:syndication_product) { instance_double Syndication::Product, master_or_variant_id: 1001, index!: true }
    let(:algolia_product_id) { syndication_product.master_or_variant_id }
    let(:algolia_index) { instance_double AlgoliaSearch::SafeIndex, delete_object: true }

    before do
      allow(Syndication::Product).to receive(:algolia_index).and_return(algolia_index)
      allow(Syndication::Product).to(
        receive(:find_by!).with(master_or_variant_id: algolia_product_id).and_return(syndication_product)
      )

      perform
    end

    context 'when remove_boolean is true' do
      let(:remove_boolean) { true }

      it 'calls delete_object on the index with the algolia_product_id' do
        expect(algolia_index).to have_received(:delete_object).with(algolia_product_id)
      end
    end

    context 'when remove_boolean is false' do
      let(:remove_boolean) { false }

      it 'calls index! on the syndication_product record' do
        expect(syndication_product).to have_received(:index!)
      end
    end
  end
end
