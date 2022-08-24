# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::ImportNotificationMailer, type: :mailer do
  let(:store) { create(:store, default: true) }

  before do
    allow(Spree::Store).to receive(:current).and_return store
  end

  describe '.marked_completed' do
    let(:mail) { described_class.marked_completed(salsify_import) }
    let(:admin_url) { Maisonette::Config.fetch('admin_url') }

    context 'when the salsify_import itself has an error' do
      let(:messages) { { error: 'there was an error' } }
      let(:salsify_import) do
        create(:salsify_import,
               :with_dev_file,
               :with_import_rows,
               :failed,
               messages: messages)
      end

      it 'sends' do
        expect(mail.to).to eq [Maisonette::Config.fetch('mail.salsify_reports_email')]
      end

      it 'details the import error' do
        expect(mail.body.encoded).to include(messages[:error])
        expect(mail.body.encoded).to have_link('Spree Product Import',
                                               href: "#{admin_url}/admin/salsify/imports/#{salsify_import.id}")
      end
    end

    context 'when salsify_import has failed and completed rows' do
      let!(:failed_row) do
        create(
          :salsify_import_row,
          :failed, :with_product,
          import: salsify_import,
          data: { 'Maisonette SKU': '123' }
        )
      end
      let!(:completed_row) { create(:salsify_import_row, :with_product, :completed, import: salsify_import) }
      let(:salsify_import) { create(:salsify_import, :with_dev_file, :completed) }

      it 'links to the admin import' do
        body = mail.body.encoded

        expect(body).to(
          have_link('Spree Product Import',
                    href: "#{admin_url}/admin/salsify/imports/#{salsify_import.id}")
        )
      end

      it 'lists successfully imported products' do
        body = mail.body.encoded

        expect(body).to match(completed_row.product.name)

        expect(body).to(
          have_link('more completed products',
                    href: "#{admin_url}/admin/salsify/imports/#{salsify_import.id}?q%5Bstate_eq%5D=completed")
        )
      end

      it 'lists failed imported rows' do
        body = mail.body.encoded

        expect(body).to match(failed_row.data['Maisonette SKU'])

        expect(body).to(
          have_link('more failed rows',
                    href: "#{admin_url}/admin/salsify/imports/#{salsify_import.id}?q%5Bstate_eq%5D=failed")
        )
      end
    end
  end
end
