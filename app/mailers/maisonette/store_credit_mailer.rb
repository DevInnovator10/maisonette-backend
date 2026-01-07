# frozen_string_literal: true

module Maisonette
  class StoreCreditMailer < Spree::BaseMailer
    include MailerHelper

    def store_credit_email(user)
      @user = user
      @introduction = {
        user_name: @user.first_name,
        heading: heading,
        image: I18n.t('spree.mail.store_credit_reminder.image'),
        content: content,
        faqs: I18n.t('spree.mail.store_credit_reminder.faqs'),
        exclude_faq_paragraph: true
      }
      @cta = { label: 'See New Offers', url: store_credit_email_url }

      subject = mail_subject I18n.t('spree.mail.store_credit_reminder.subject')
      mail(to: @user.email, from: Spree::Store.default.mail_from_address, subject: subject)
    end

    private

    def store_credit_email_url
      prepend_default_host(
        '/?utm_source=email&utm_medium=transactional&utm_campaign=store-credit'
      )
    end

    def prepend_default_host(path)
      return path if ActionMailer::Base.default_url_options[:host].nil?

      "#{ActionMailer::Base.default_url_options[:host]}#{path}"
    end

    def fetch_store_credit_amount
      @fetch_store_credit_amount ||= @user.total_available_store_credit
    end

    def content
      I18n.t('spree.mail.store_credit_reminder.introduction',
             user_email: @user.email,
             credit_amount: fetch_store_credit_amount.to_money.format)
    end

    def heading
      I18n.t('spree.mail.store_credit_reminder.heading',
             user_email: @user.email,
             credit_amount: fetch_store_credit_amount.to_money.format)
    end
  end
end
