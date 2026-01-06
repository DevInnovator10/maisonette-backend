# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::MiniBirthdayMailer, type: :mailer do
  describe '#notify' do
    let(:mail) { described_class.notify(mini, promotion_code) }

    let(:promotion_code) { create :promotion_code }
    let(:mini) { create :mini }

    it 'includes the mailer helper' do
      expect(described_class.ancestors).to include MailerHelper
    end

    it 'renders the headers' do
      expect(mail.to).to include mini.user.email
      expect(mail.from).to eq [Spree::Store.default.mail_from_address]
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include promotion_code.value.upcase
    end
  end
end
