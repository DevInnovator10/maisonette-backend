# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::BaseSaleExportWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:perform) { worker.perform(sale_id, search_query, user_id) }

    let(:user) { create(:user, email: 'user@email.com') }
    let(:sale) { create(:sale, name: 'Sale #1') }

    let(:sale_id) { sale.id }
    let(:search_query) { {} }
    let(:user_id) { user.id }

    let(:collection) { Maisonette::Sale.all }
    let(:csv_filename) { ['filename', '.csv'] }

    let(:mailer) { OpenStruct.new(export_email: message_delivery) }
    let(:message_delivery) { instance_double(ActionMailer::Parameterized::MessageDelivery, deliver_now!: true) }

    let(:tempfile) { Tempfile.new }
    let(:context) { instance_double('Context', success?: true, file: tempfile, csv_filename: csv_filename) }

    before do
      allow(worker).to receive(:collection).and_return(collection)

      allow(Maisonette::BuildSaleCsvInteractor).to receive(:call).and_return(context)
      allow(Maisonette::SaleExportMailer).to receive(:with).and_return(mailer)
    end

    it 'calls the BuildSaleCsvInteractor with the right params' do
      perform

      expect(Maisonette::BuildSaleCsvInteractor).to have_received(:call).with(
        collection: collection, csv_filename: nil, csv_headers: nil, csv_row_builder: nil
      )
    end

    it 'calls the mailer' do
      file_path = tempfile.path

      perform

      expect(Maisonette::SaleExportMailer).to have_received(:with).with(
        recipient: user.email,
        subject: 'Maisonette | Sale Export Completed - Sale #1',
        attachment_path: file_path,
        attachment_name: csv_filename.join
      )
    end

    it 'removes the CSV' do
      allow(tempfile).to receive(:close).and_call_original
      allow(tempfile).to receive(:unlink).and_call_original

      perform

      expect(tempfile).to have_received(:close)
      expect(tempfile).to have_received(:unlink)
    end
  end

  describe '#collection' do
    subject(:collection) { worker.send(:collection) }

    it 'raises an exception' do
      expect { collection }.to raise_error(NotImplementedError)
    end
  end
end
