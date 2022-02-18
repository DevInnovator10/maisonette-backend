# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::RemoveOrphanSalePriceWorker do
  let(:sale) { create(:sale, percent_off: 0.15) }
  let(:perform) { described_class.new.perform }
  let(:offer_settings) { create(:offer_settings, vendor_sku: 'vs-005') }
  let(:sale_price) { create :sale_price, enabled: true }
  let(:temp_file) { Tempfile.new }
  let(:context) { instance_double('Context', success?: true, file: temp_file, csv_filename: file_name) }
  let(:file_name) { 'orphan_sale_prices.csv' }
  let(:message) { 'Ophan data process complete, please check detailed records' }
  let(:slack_channel) { 'tech-sales-orphan-data' }
  let(:mailer) { OpenStruct.new(delete_all_email: message_delivery) }
  let(:message_delivery) { instance_double(ActionMailer::Parameterized::MessageDelivery, deliver_now!: true) }

  before do
    allow(Maisonette::Slack).to receive(:notify)
    allow(Maisonette::OrphanSalePriceDeletionMailer).to receive(:with).and_return(mailer)
    create(:sale_sku_configuration, sale: sale, offer_settings: offer_settings)
    allow(Tempfile).to receive(:new).and_call_original
    allow(Tempfile).to receive(:new).with(['orphan_sale_prices', '.csv']).and_return(temp_file)
    allow(temp_file).to receive(:unlink)
    allow(Maisonette::BuildOrphanCsvInteractor).to receive(:call).and_return(context)
    _sale_sku = create :sale_sku_configuration, offer_settings: offer_settings, sale: sale, sale_price: sale_price
  end

  after do
    allow(temp_file).to receive(:unlink).and_call_original
    temp_file.unlink
  end

  context 'when orphan sale prices are present' do
    let(:orphan_sale_price_count) { 1 }

    before do
      _orphan_price = create :sale_price, enabled: true
    end

    it 'removes orphan sale record & does not effect actual records' do
      expect(Spree::SalePrice.count).to eq(2)
      perform
      expect(Spree::SalePrice.count).to eq(1)
      expect(Maisonette::Slack).to have_received(:notify).with(channel: slack_channel, payload: message)
      expect(Maisonette::OrphanSalePriceDeletionMailer).to have_received(:with).with(
        recipient: 'tech-sales-orphan-dat-aaaah72lg5wqfp6uzig2eikwxe@maisonette.slack.com',
        orphan_sale_price_count: orphan_sale_price_count,
        file_path: temp_file.path
      )
    end
  end

  context 'when orphan sale prices are not present' do
    let(:orphan_sale_price_count) { 0 }

    it 'removes orphan sale record & does not effect actual records' do
      expect(Spree::SalePrice.count).to eq(1)
      perform
      expect(Spree::SalePrice.count).to eq(1)
      expect(Maisonette::Slack).not_to have_received(:notify).with(channel: slack_channel, payload: message)
      expect(Maisonette::OrphanSalePriceDeletionMailer).not_to have_received(:with).with(
        recipient: 'tech-sales-orphan-dat-aaaah72lg5wqfp6uzig2eikwxe@maisonette.slack.com',
        orphan_sale_price_count: orphan_sale_price_count,
        file_path: temp_file.path
      )
    end
  end
end
