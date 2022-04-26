# frozen_string_literal: true

module Spree::UserMailer::WelcomeEmail
  def self.prepended(base)
    base.include MailerHelper
  end

  def welcome(user)
    @store_url = Maisonette::Config.fetch('base_url')
    @introduction = {
      user_name: user.first_name,
      heading: I18n.t('spree.mail.welcome.heading'),
      image: I18n.t('spree.mail.welcome.image'),
      content: I18n.t('spree.mail.welcome.introduction')
    }
    subject = mail_subject(I18n.t('spree.mail.welcome.subject'))
    mail(to: user.email, from: Spree::Store.default.mail_from_address, subject: subject)
  end
end
