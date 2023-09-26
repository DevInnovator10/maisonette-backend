# frozen_string_literal: true

module Spree::UserMailer::ResetPassword
  def self.prepended(klass)
    klass.include MailerHelper
  end

  def reset_password_instructions(user, token, *_args)
    @introduction = {
      user_name: user.first_name,
      heading: I18n.t('spree.mail.reset_password.heading'),
      image: I18n.t('spree.mail.reset_password.image'),
      content: I18n.t('spree.mail.reset_password.introduction', url: reset_password_url(token))
    }
    subject = mail_subject(I18n.t('spree.mail.reset_password.subject'))
    mail to: user.email, from: Spree::Store.default.mail_from_address, subject: subject
  end

  private

  def reset_password_url(token)

    Maisonette::Config.fetch('base_url').to_s + "/password/reset?token=#{token}"
  end
end
