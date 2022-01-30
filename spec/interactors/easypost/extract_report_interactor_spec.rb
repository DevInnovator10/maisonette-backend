# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::ExtractReportInteractor do
  describe 'call' do
    subject(:interactor) do
      described_class.call(
        document: document
      )
    end

    let(:document) { file_fixture('easypost/sample_shipment_invoice.csv.zip').read }

    it 'creates csv tables' do
      expect(interactor.csv_tables.count).to eq 1
      expect(interactor.csv_tables.last.by_col[0]).to match_array(
        %w[shp_c214f3d86bda479880c0695f510ebdc9 shp_26e202afb1de4be6bc4080f93ee09003
           shp_9cc7493a68cf407e909049315ef5a221]
      )
    end
  end
end
