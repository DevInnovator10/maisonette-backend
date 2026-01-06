# frozen_string_literal: true

namespace :algolia do
  desc 'Sync algolia rules for edits'
  task sync_algolia_rules: :environment do
    edits = Spree::Taxon.joins(:taxonomy).where(spree_taxonomies: { name: Spree::Taxonomy::EDITS })
    puts "Sync #{edits.count} edits"

    Algolia::SyncEditsRulesWorker.perform_async([edits.pluck(:id)])
  end

  desc 'Sync algolia rules for lpc edits with position'
  task sync_algolia_rules_with_position: :environment do
    puts 'Starging CreateLpcEditsRulesPositionWorker'
    Algolia::SyncEditsRulesPositionWorker.perform_async(ENV['LANDING_PAGE_LIST_FILE'])
  end
end
