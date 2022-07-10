# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Algolia::SyncEditsRulesWorker do
    describe '#perform' do
    subject(:perform) { described_class.new.perform([taxon_edits_id]) }

    let(:edits_taxon) do
      instance_double Spree::Taxon, id: 1001, name: 'Just In', taxonomy: edits_taxonomy, permalink: 'edits/just-in'
    end
    let(:edits_taxonomy) { instance_double Spree::Taxonomy, name: 'Edits' }
    let(:taxon_edits_id) { edits_taxon.id }
    let(:algolia_index) { instance_double AlgoliaSearch::SafeIndex }
    let(:rule) do
      {
        objectID: object_id,
        conditions: [{
          alternatives: false,
          anchoring: 'is',
          pattern: '',
          filters: 'edits: just-in'
        }],
        consequence: {
          userData: {
            name: edits_taxon.name
          }
        },
        enabled: true

      }
    end
    let(:object_id) { 'edits-rule-just-in' }

    before do
      allow(Syndication::Product).to receive(:algolia_index).and_return(algolia_index)
      allow(algolia_index).to receive(:save_rules).with([rule])
      allow(edits_taxon).to receive(:algolia_rule_object_id).and_return(object_id)
      allow(Spree::Taxon).to(
        receive(:where).with(id: [taxon_edits_id])
      ).and_return([edits_taxon])

      perform
    end

    it 'calls save_rules on the index with array of rules' do
      expect(algolia_index).to have_received(:save_rules).with([rule])
    end
  end
end
