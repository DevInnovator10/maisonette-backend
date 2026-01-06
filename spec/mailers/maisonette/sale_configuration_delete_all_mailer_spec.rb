# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::SaleConfigurationDeleteAllMailer, type: :mailer do
  describe '#delete_all_email' do
    subject(:mail) { described_class.with(args).delete_all_email }

    let(:args) do
      { recipient: recipient,
        sale_name: sale_name,
        configuration_count: configuration_count,
        file_path: file_path }
    end
    let(:recipient) { 'some_email@maisonette.com' }
    let(:sale_name) { 'Sale Name' }
    let(:configuration_count) { 1 }
    let(:file_path) { 'path/deleted_products.csv' }
    let(:sample_data) { "header1;header2\n" }

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(file_path).and_return(sample_data)
    end

    it 'renders the headers' do
      recipient_list = [recipient, Maisonette::Config.fetch('mail.merch_email')]
      expect(mail.to).to match_array(recipient_list)
      expect(mail.from).to eq [Spree::Store.default.mail_from_address]
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include "Delete all products completed by user: #{recipient}"
      expect(mail.body.encoded).to include "#{configuration_count} SKUs successfully deleted"
    end

    context 'when email is generated successfully' do
      it 'renders the subject' do
        expect(mail.subject).to eq "[#{Rails.env.upcase}] Maisonette | Deleted Products from #{sale_name}"
      end

      it 'includes one attachment' do
        expect(mail.attachments.count).to eq 1
      end

      it 'includes the deleted products attachment' do
        attachment = mail.attachments.first
        expect(File).to have_received(:read).with(file_path)

        expect(attachment.filename).to eq('deleted_products.csv')
        expect(attachment.content_type).to include 'text/csv'
      end
    end

    context 'when delivered' do
      let(:rails_logger) { instance_double ActiveSupport::Logger, info: true }

      before do
        allow(Rails).to receive(:logger).and_return(rails_logger)
        mail.deliver_now
      end

      it 'logs the mail headers summary' do
        expect(rails_logger).to have_received(:info)
      end
    end
  end
end
