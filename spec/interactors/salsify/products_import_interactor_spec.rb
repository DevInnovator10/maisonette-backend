# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::ProductsImportInteractor do
    describe 'hooks' do
    it 'has before hooks' do
      expect(described_class.before_hooks).to eq [:validate_and_init, :prepare_taxonomies, :prepare_properties]
    end
  end

  describe '#call' do
    let(:interactor) { described_class.new }

    before do
      allow(interactor).to receive_messages(fetch: true, parse: true, process: true)
      interactor.call
    end

    it 'calls fetch' do
      expect(interactor).to have_received(:fetch)
    end

    it 'calls parse' do
      expect(interactor).to have_received(:parse)
    end

    it 'calls process' do
      expect(interactor).to have_received(:process)
    end
  end

  describe '#fetch' do
    let(:interactor) { described_class.new }
    let(:matcher) { described_class::MATCHER }
    let(:source_path) { described_class::SOURCE_PATH }
    let(:backup_path) { described_class::BACKUP_PATH }
    let(:salsify_ftp) { instance_double Salsify::FTP }
    let(:file_1) { 'file_1' }
    let(:file_2) { 'file_2' }
    let(:import_1) { instance_double Salsify::Import }
    let(:import_2) { instance_double Salsify::Import }

    before do
      allow(Salsify::FTP).to receive(:new).and_return(salsify_ftp)
      allow(salsify_ftp).to receive(:fetch).and_yield(file_1).and_yield(file_2)
      allow(Salsify::Import).to receive(:create!).and_return(import_1, import_2)

      interactor.send :fetch
    end

    it 'creates a Salsify::FTP with matcher and remote paths' do
      expect(Salsify::FTP).to have_received(:new).with(matcher: matcher,
                                                       source_path: source_path,
                                                       backup_path: backup_path)
    end

    it 'fetches the data from the FTP' do
      expect(salsify_ftp).to have_received(:fetch)
    end

    it 'creates Salsify::Import records and saves to instance variable' do
      expect(Salsify::Import).to(
        have_received(:create!).with(file_to_import: file_1, state: :created, import_type: :products)
      )
      expect(Salsify::Import).to(
        have_received(:create!).with(file_to_import: file_2, state: :created, import_type: :products)
      )

      expect(interactor.instance_variable_get('@product_imports')).to match_array([import_1, import_2])
    end

    context 'with some local files' do
      let(:interactor) { described_class.new(local_files: [salsify_import_file]) }
      let(:salsify_import) { build :salsify_import, :with_dev_file }
      let(:salsify_import_file) { Rails.root.join('spec', 'fixtures', 'salsify', salsify_import.file_to_import) }

      it 'processes local files' do
        expect(salsify_ftp).not_to have_received(:fetch)
        expect(Salsify::Import).to(
          have_received(:create!).with(file_to_import: salsify_import_file, state: :created, import_type: :products)
        )
      end
    end
  end

  describe '#parse' do
    let(:interactor) { described_class.new }
    let(:product_imports) { [import_1, import_2] }
    let(:import_1) { instance_double Salsify::Import, update: true }
    let(:import_2) { instance_double Salsify::Import, update: true, id: 5 }
    let(:local_path) { 'some/local/path' }
    # rubocop:disable RSpec/VerifiedDoubles
    let(:successful_context) { double Interactor::Context, success?: true, messages: 'msg_1' }
    let(:failed_context) { double Interactor::Context, success?: false, messages: 'msg_2' }
    # rubocop:enable RSpec/VerifiedDoubles
    let(:failed_import_exception) do
      Salsify::Exception.new(failed_context.messages, resource_class: Salsify::Import, resource_id: import_2.id)
    end

    before do
      interactor.instance_variable_set('@product_imports', product_imports)
      interactor.instance_variable_set('@local_path', local_path)

      allow(Salsify::ParseInteractor).to receive(:call).and_return(successful_context, failed_context)
      allow(Sentry).to receive(:capture_exception_with_message)

      interactor.send :parse
    end

    it 'calls Salsify::ParseInteractor with each product import' do
      product_imports.each do |import|
        options = { import: import, local_path: local_path, delete_local_file: nil }
        expect(Salsify::ParseInteractor).to have_received(:call).with(options)
      end
    end

    it 'updates the import states' do
      expect(import_1).to have_received(:update).with(messages: successful_context.messages, state: :imported)
      expect(import_2).to have_received(:update).with(messages: failed_context.messages, state: :failed)
    end

    it 'captures exception for the failed imports' do
      expect(Sentry).to have_received(:capture_exception_with_message).with(failed_import_exception)
    end
  end

  describe '#process' do
    let(:interactor) { described_class.new }
    let(:product_imports) { class_double Salsify::Import, imported: imported_product_imports }
    let(:imported_product_imports) { class_double Salsify::Import }
    let(:imported_product_import_1) do
      instance_double Salsify::Import, processing!: true, salsify_import_rows: salsify_import_rows_1
    end
    let(:imported_product_import_2) do
      instance_double Salsify::Import, processing!: true, salsify_import_rows: salsify_import_rows_2
    end
    let(:salsify_import_rows_1) do
      class_double Salsify::ImportRow, created: [created_row_1, created_row_2, created_row_3]
    end
    let(:salsify_import_rows_2) { class_double Salsify::ImportRow, created: [created_row_4] }
    let(:created_row_1) { build_stubbed(:salsify_import_row, id: 1, unique_key: '5') }
    let(:created_row_2) { build_stubbed(:salsify_import_row, id: 2, unique_key: '5') }
    let(:created_row_3) { build_stubbed(:salsify_import_row, id: 3, unique_key: '10') }
    let(:created_row_4) { build_stubbed(:salsify_import_row, id: 4, unique_key: '15') }

    before do
      allow(Salsify::Import).to receive(:by_type).with(:products).and_return(product_imports)
      allow(Salsify::ImportRowWorker).to receive(:perform_async)
      allow(imported_product_imports).to receive(:find_each).and_yield(imported_product_import_1)
                                                            .and_yield(imported_product_import_2)

      interactor.send :process
    end

    it 'marks the imports as processing' do
      expect(imported_product_import_1).to have_received(:processing!)
      expect(imported_product_import_2).to have_received(:processing!)
    end

    it 'groups the rows by unique_key and calls Salsify::ImportRowWorker' do
      expect(Salsify::ImportRowWorker).to have_received(:perform_async).with('5', [1, 2])
      expect(Salsify::ImportRowWorker).to have_received(:perform_async).with('10', [3])
      expect(Salsify::ImportRowWorker).to have_received(:perform_async).with('15', [4])
    end
  end

  describe '#prepare taxonomies' do
    subject(:prepare_taxonomies) { interactor.send :prepare_taxonomies }

    let(:interactor) { described_class.new }

    it 'creates the required taxonomies and taxons' do
      expect { prepare_taxonomies }.to change { Spree::Taxonomy.count }.from(0).to(Salsify::TAXONOMIES.size)
      expect(Spree::Taxon.count).to eq(Spree::Taxonomy.count)
    end
  end

  describe '#prepare properties' do
    subject(:prepare_properties) { interactor.send :prepare_properties }

    let(:interactor) { described_class.new }
    let(:expected_property_size) { Salsify::PRODUCT_PROPERTIES.size + Salsify::MULTI_VALUE_PRODUCT_PROPERTIES.size }

    it 'creates the required properties' do
      expect { prepare_properties }.to change { Spree::Property.count }.from(0).to(expected_property_size)
    end
  end
end
