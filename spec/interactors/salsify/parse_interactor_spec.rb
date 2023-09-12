# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::ParseInteractor do
  let(:local_path) { Rails.root.join('spec', 'fixtures', 'salsify').to_s }

  before { allow(Maisonette::Config).to receive(:fetch).with('salsify.local_path').and_return(local_path) }

  describe '#call' do
    subject(:interactor_call) { described_class.call(options) }

    let(:options) { {} }
    let(:import) { create :salsify_import, :with_dev_file, :with_import_rows }

    before do
      context = instance_double('Context', failure?: false)
      allow(Salsify::PrepareRowInteractor).to receive(:call).and_return(context)
      allow(File).to receive_messages(delete: true, exist?: true)
    end

    it { is_expected.to be_a_failure }
    it { expect(interactor_call.messages).to eq Salsify.salsify_error(:import_missing) }

    context 'with import data' do
      let(:options) { { import: import } }

      it { is_expected.to be_a_failure }
      it { expect(interactor_call.messages).to eq Salsify.salsify_error(:local_path_missing) }
    end

    context 'with required parameters' do
      let(:options) { { import: import, local_path: local_path } }

      it { is_expected.to be_a_success }

      context 'with an "development-account" CSV file' do
        let(:input_file) do
          Rails.root.join('spec', 'fixtures', 'salsify').glob('*-development-account*product*.csv').last
        end
        let(:import) { create :salsify_import, file_to_import: File.basename(input_file) }
        let(:csv_data) { Salsify.parse_csv_file(input_file) }

        before { allow(Salsify).to receive(:parse_csv_file).and_return(csv_data) }

        it { is_expected.to be_a_success }
        it 'calls the prepare row interactor per each row to import' do
          interactor_call
          expect(Salsify::PrepareRowInteractor).to have_received(:call).exactly(csv_data.count).times
        end

        it 'deletes the files' do
          interactor_call
          expect(File).to have_received(:delete).with(input_file)
        end

        context 'with delete_local_file set to false' do
          let(:options) { { import: import, local_path: local_path, delete_local_file: false } }

          it "doesn't delete the file" do
            interactor_call
            expect(File).not_to have_received(:delete).with(input_file)
          end
        end
      end

      context 'with an "inc" CSV file' do
        let(:input_file) { Rails.root.join('spec', 'fixtures', 'salsify').glob('*-inc*product*.csv').last }
        let(:import) { create :salsify_import, file_to_import: File.basename(input_file) }
        let(:csv_data) { Salsify.parse_csv_file(input_file) }

        before { allow(Salsify).to receive(:parse_csv_file).and_return(csv_data) }

        it { is_expected.to be_a_success }
        it 'calls the prepare row interactor per each row to import' do
          interactor_call
          expect(Salsify::PrepareRowInteractor).to have_received(:call).exactly(csv_data.count).times
        end

        it 'deletes the files' do
          interactor_call
          expect(File).to have_received(:delete).with(input_file)
        end
      end
    end
  end
end
