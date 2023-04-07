# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ShopDocumentsMailer, type: :mailer do
  describe '#shop_documents_email' do
    subject(:mail) { described_class.with(args).shop_documents_email }

    let(:args) do
      { recipient: recipient,
        vendor_name: vendor_name,
        archive_path: archive_path,
        orders: orders,
        orders_with_fixed_errors: orders_with_fixed_errors,
        documents_time: documents_time }
    end
    let(:vendor_name) { 'Lindsey Berns' }
    let(:archive_path) { 'some path' }
    let(:documents_time) { '2020-10-14 11:00:00 -0400' }
    let(:orders) { %w[A123-B B234-C C345-D] }
    let(:orders_with_fixed_errors) { [] }
    let(:recipient) { 'some_email@maisonette.com' }
    let(:sample_data) { file_fixture('mirakl/sample_order_documents.zip').read }

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(archive_path).and_return(sample_data)
    end

    it 'includes the mailer helper' do
      expect(described_class.ancestors).to include MailerHelper
    end

    it 'renders the headers' do
      expect(mail.to).to include recipient
      expect(mail.from).to eq [Spree::Store.default.mail_from_address]
      expect(mail.bcc).to eq [Maisonette::Config.fetch('mail.ops_support_email')]
    end

    it 'renders the subject' do
      expect(mail.subject).to include I18n.t('spree.mail.mirakl_shop_documents.subject',
                                             vendor: vendor_name,
                                             datetime: '')
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include "Orders' documents"
      expect(mail.body.encoded).to include 'Accepted Orders'
      expect(mail.body.encoded).not_to include 'Fixed Orders'
      orders.map do |order|
        expect(mail.body.encoded).to include order
      end
    end

    it 'includes the attachment' do
      expect(mail.attachments.count).to eq 1
      expect(File).to have_received(:read).with(archive_path)
      attachment = mail.attachments.first
      expect(attachment.filename).to match(/documents_.+\.zip/)
      expect(attachment.content_type).to include 'application/zip'
    end

    context 'when there are orders with fixed errors' do
      let(:orders_with_fixed_errors) { %w[A321-A] }

      it 'renders the body with fixed orders' do
        expect(mail.body.encoded).to include 'Fixed Orders'
        orders_with_fixed_errors.map do |order|
          expect(mail.body.encoded).to include order
        end
      end

      context 'when there are only orders with fixed errors' do
        let(:orders) { [] }

        it 'renders the body with only fixed orders' do
          expect(mail.body.encoded).to include 'Fixed Orders'
          expect(mail.body.encoded).not_to include 'Accepted Orders'
          orders_with_fixed_errors.map do |order|
            expect(mail.body.encoded).to include order
          end
        end
      end
    end

    context 'with batch data' do
      let(:args) do
        {
          recipient: recipient,
          archive_path: archive_path,
          orders: orders,
          orders_with_fixed_errors: [],
          documents_time: documents_time,
          batch_group: 1,
          batch_groups: 3
        }
      end

      it 'includes the batch informations in the subject' do
        expect(mail.subject).to match(/ - \d of \d$/)
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
