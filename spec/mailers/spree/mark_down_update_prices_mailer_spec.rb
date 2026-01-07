# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::MarkDownUpdatePricesMailer, type: :mailer do
  let(:mark_down_title) { 'Some Mark Down' }

  describe '#send_updated_email' do
    let(:mail) { described_class.send_updated_email(mark_down_title) }

    it 'renders the headers' do
      expect(mail.to).to match_array [Maisonette::Config.fetch('mail.merch_email'),
                                      Maisonette::Config.fetch('mail.support_email')]
      expect(mail.from).to eq [Spree::Store.default.mail_from_address]
      expect(mail.subject).to eq "Maisonette | Mark Down Prices Update Successful - #{mark_down_title}"
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include 'Sale Prices were successfully updated'
    end
  end

  describe '#send_destroyed_email' do
    let(:mail) { described_class.send_destroyed_email(mark_down_title) }

    it 'renders the headers' do
      expect(mail.to).to match_array [Maisonette::Config.fetch('mail.merch_email'),
                                      Maisonette::Config.fetch('mail.support_email')]
      expect(mail.from).to eq [Spree::Store.default.mail_from_address]
      expect(mail.subject).to eq "Maisonette | Mark Down Prices Destroyed Successful - #{mark_down_title}"
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include 'Sale Prices were successfully destroyed'
    end
  end

  describe '#send_updated_error_email' do
    let(:mail) { described_class.send_updated_error_email(mark_down_title) }

    it 'renders the headers' do
      expect(mail.to).to match_array [Maisonette::Config.fetch('mail.merch_email'),
                                      Maisonette::Config.fetch('mail.support_email')]
      expect(mail.from).to eq [Spree::Store.default.mail_from_address]
      expect(mail.subject).to eq "Maisonette | Mark Down Prices Update Unsuccessful - #{mark_down_title}"
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include 'Sale Prices were not successfully updated'
    end
  end

  describe '#send_destroyed_error_email' do
    let(:mail) { described_class.send_destroyed_error_email(mark_down_title) }

    it 'renders the headers' do
      expect(mail.to).to match_array [Maisonette::Config.fetch('mail.merch_email'),
                                      Maisonette::Config.fetch('mail.support_email')]
      expect(mail.from).to eq [Spree::Store.default.mail_from_address]
      expect(mail.subject).to eq "Maisonette | Mark Down Prices Destroyed Unsuccessful - #{mark_down_title}"
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include 'Sale Prices were not successfully destroyed'
    end
  end
end
