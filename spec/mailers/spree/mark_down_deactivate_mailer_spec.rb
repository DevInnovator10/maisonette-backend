# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::MarkDownDeactivateMailer, type: :mailer do
  let(:mark_down) { build_stubbed :mark_down, title: title }
  let(:title) { 'Sample Mark Down' }

  describe '#notify_deactivate' do
    let(:mail) { described_class.notify_deactivate(mark_down) }

    it 'renders the headers' do
      expect(mail.to).to match_array [Maisonette::Config.fetch('mail.merch_email'),
                                      Maisonette::Config.fetch('mail.support_email')]
      expect(mail.from).to eq [Spree::Store.default.mail_from_address]
      expect(mail.subject).to eq "Maisonette | Mark Down deactivated - #{title}"
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include title
      expect(mail.body.encoded).to include 'expired'
    end
  end
end
