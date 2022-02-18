# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/admin/migration_logs/:id', type: :feature, js: false do
  let(:log) do
    create :migration_log, legacy_id: 1, order_number: 'R123456789', migrable_type: 'Spree::Order'
  end

  let(:log2) do
    create :migration_log, legacy_id: 1, order_number: 'R123456789', migrable_type: 'Spree::LineItem', parent: log
  end

  stub_authorization!

  context 'when visiting logs show' do
    it 'shows the details of a Spree::Order entity log' do
      visit spree.admin_migration_log_path(log)
      expect(page.title).to eq "#{log.id} - Migration Logs"
      expect(page.body).to include 'Migrable type'
    end

    it 'shows the details of a Spree::LineItem entity log' do
      visit spree.admin_migration_log_path(log2)
      expect(page.title).to eq "#{log2.id} - Migration Logs"
      expect(page.body).to include 'Migrable type'
    end
  end
end
