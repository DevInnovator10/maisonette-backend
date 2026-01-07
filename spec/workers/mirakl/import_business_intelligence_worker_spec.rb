# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ImportBusinessIntelligenceWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    before do
      allow(Mirakl::RetrieveBiCsvInteractor).to receive(:call).with(csv_directory: 'tmp/miraklbi.csv')
      allow(worker).to receive(:add_mirakl_data_to_business_intelligence_table).with('tmp/miraklbi.csv')
      allow(Sentry).to receive(:capture_exception_with_message)
    end

    it 'calls methods without a hitch' do
      expect { worker.perform }.not_to raise_error
    end
  end

  describe '#add_mirakl_data_to_business_intelligence_table' do
    let(:add_single_line_to_business_intelligence_table) do
      described_class.new.send :add_mirakl_data_to_business_intelligence_table,
                               file_fixture('mirakl/BI01/BI01_single_line.csv')
    end

    context 'when the table is empty' do
      it 'add a row of bi data' do
        expect { add_single_line_to_business_intelligence_table }.to change(Mirakl::BusinessIntelligence, :count).by(1)
      end
    end

    context 'when importing a not updated line that already exists in the table' do
      before do
        add_single_line_to_business_intelligence_table
      end

      it 'does not add another row' do
        expect { add_single_line_to_business_intelligence_table }.not_to change(Mirakl::BusinessIntelligence, :count)
      end

      it 'does not update a row' do
        expect { add_single_line_to_business_intelligence_table }.not_to(
          change(Mirakl::BusinessIntelligence.find_by(order_line_id: 'COTTON-123-A-1'), :updated_at)
        )
      end
    end

    context 'when importing multiple lines with a line that already exists in the table' do
      before do
        described_class.new.send :add_mirakl_data_to_business_intelligence_table,
                                 file_fixture('mirakl/BI01/BI01_repeated_line.csv')
      end

      it 'add mirakl bi data to table' do
        expect(Mirakl::BusinessIntelligence.count).to eq(3)

      end
    end

    context 'when importing an updated line' do
      before do
        add_single_line_to_business_intelligence_table
        described_class.new.send :add_mirakl_data_to_business_intelligence_table,
                                 file_fixture('mirakl/BI01/BI01_updated_line.csv')
      end

      it 'add then update a bi line' do
        expect(Mirakl::BusinessIntelligence.find_by(order_line_id: 'COTTON-123-A-1')
                                           .order_line_state).to eq('ACCEPTED')
      end
    end

    context 'when importing with extra semicolons in the JSON' do
      before do
        described_class.new.send :add_mirakl_data_to_business_intelligence_table,
                                 file_fixture('mirakl/BI01/BI01_extra_semicolon.csv')
      end

      it 'add mirakl bi line with no problem' do
        expect(Mirakl::BusinessIntelligence.count).to eq(1)
      end
    end

    context 'when importing with malformed data' do
      subject(:add_mirakl_data_to_business_intelligence_table) do
        described_class.new.send :add_mirakl_data_to_business_intelligence_table,
                                 file_fixture('mirakl/BI01/BI01_malformed_data.csv')
      end

      it 'reports the error to Sentry with the proper error message' do
        expect(Sentry).to(
          receive(:capture_exception_with_message).with( # rubocop:disable RSpec/MessageSpies
            instance_of(CSV::MalformedCSVError),
            message: file_fixture('mirakl/BI01/BI01_malformed_data.csv').read
          )
        )

        add_mirakl_data_to_business_intelligence_table
      end
    end

    context 'when importing with encrypted data' do
      before do
        described_class.new.send :add_mirakl_data_to_business_intelligence_table,
                                 file_fixture('mirakl/BI01/BI01_encrypted_data.csv')
      end

      it 'add mirakl bi line with no problem' do
        expect(Mirakl::BusinessIntelligence.count).to eq(1)
      end
    end
  end
end
