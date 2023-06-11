# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Salsify Data Imports Admin', type: :request do
  stub_authorization!

  let(:salsify_imports) { create_list :salsify_import, 3, :with_dev_file }

  before { salsify_imports }

  describe '#index' do
    subject(:described_method) { get spree.admin_salsify_imports_path }

    before { described_method }

    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:imports).size).to eq salsify_imports.size }
  end

  describe '#show' do
    subject(:described_method) { get spree.admin_salsify_import_path(salsify_imports.first.id) }

    before { described_method }

    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:import)).to eq salsify_imports.first }
  end

  describe '#re_process' do
    subject(:described_method) { put spree.re_process_admin_salsify_import_path(salsify_import.id) }

    let(:salsify_import) { create :salsify_import, :with_dev_file }
    let(:failed_salsify_import_rows) do
      create_list :salsify_import_row, 1, salsify_import: salsify_import, state: 'failed'
    end
    let(:created_salsify_import_row) do
      create :salsify_import_row, salsify_import: salsify_import
    end

    before do
      failed_salsify_import_rows
      created_salsify_import_row

      allow(Salsify::ImportRowWorker).to receive(:perform_async)
    end

    it 'performs only the failed import rows' do
      described_method

      expect(Salsify::ImportRowWorker).to(
        have_received(:perform_async).with(failed_salsify_import_rows.first.unique_key,
                                           failed_salsify_import_rows.pluck(:id))
      )
      expect(Salsify::ImportRowWorker).not_to(
        have_received(:perform_async).with(created_salsify_import_row.unique_key,
                                           [created_salsify_import_row.id])
      )
    end
  end
end
