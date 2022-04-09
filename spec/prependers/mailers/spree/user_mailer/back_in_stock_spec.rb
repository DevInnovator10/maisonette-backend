# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::UserMailer::BackInStock, type: :mailer do
    let(:described_class) { Spree::UserMailer }
  let(:email) { FFaker::Internet.email }

  describe '#back_in_stock' do
    let(:stock_request) { create :stock_request, email: email }
    let(:mail) { described_class.back_in_stock(stock_request) }

    it 'includes MailerHelper' do
      expect(described_class.ancestors).to include MailerHelper
    end

    it 'renders the headers' do
      expect(mail.to).to include email
      expect(mail.from).to eq [Spree::Store.default.mail_from_address]
      expect(mail.subject).to eq 'Maisonette | ' + I18n.t('spree.mail.back_in_stock.subject')
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include I18n.t('spree.mail.back_in_stock.content')
    end
  end
end
