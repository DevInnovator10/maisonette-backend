# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::MiraklOffersImportInteractor do
  describe 'hooks' do
    it 'has before hooks' do
      expect(described_class.before_hooks).to eq [:validate_and_init]
    end
  end

  describe '#call' do
    subject(:interactor_call) { interactor.call }

    let(:interactor) { described_class.new }
    let(:salsify_ftp) { instance_double Salsify::FTP }
    let(:offer_matcher) { '*mirakl_offer_feed_maisonette*.csv' }
    let(:offer_price_matcher) { '*mirakl_price_inventory_maisonette*.csv' }
    let(:source_path) { '/Mirakl/salsify_output' }
    let(:backup_path) { '/Mirakl/salsify_output/backup' }
    let(:mirakl_offer_export_job) { instance_double Salsify::MiraklOfferExportJob, offers: offers_attachment }
    let(:offers_attachment) { instance_double ActiveStorage::Attached::One, attach: true }
    let(:file) { instance_double File }

    before do
      allow(Salsify::FTP).to receive(:new).and_return(salsify_ftp)
      allow(salsify_ftp).to receive(:fetch).and_yield('a_file')
      allow(Salsify::MiraklOfferExportJob).to receive_messages(create: mirakl_offer_export_job)
      allow(File).to receive_messages(open: file)

      interactor_call
    end

    it 'creates a Salsify::FTP with matcher and remote paths' do
      expect(Salsify::FTP).to have_received(:new).with(matcher: offer_matcher,
                                                       source_path: source_path,
                                                       backup_path: backup_path)
      expect(Salsify::FTP).to have_received(:new).with(matcher: offer_price_matcher,
                                                       source_path: source_path,
                                                       backup_path: backup_path)
    end

    it 'fetches the data from the FTP for both matchers' do
      expect(salsify_ftp).to have_received(:fetch).twice
    end

    it 'attaches the file to the Salsify::MiraklOfferExportJob' do
      expect(offers_attachment).to(
        have_received(:attach).with(io: file, filename: 'a_file', content_type: 'text/csv').twice
      )
    end
  end
end
