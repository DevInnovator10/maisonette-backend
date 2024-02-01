# frozen_string_literal: true

module Spree::OrderMailer::ConfirmEmail
  def self.prepended(base)
    base.include MailerHelper
  end

  def confirm_email(order, resend = false)
    @order = order.is_a?(Spree::Order) ? order : Spree::Order.find(order)
    opts = jifiti_options(@order)
    opts.reverse_merge! default_options(@order, resend)
    create_confirmation_email(@order, opts)
  end

  private

  def create_confirmation_email(order, opts = {})
    @order = order
    @introduction = opts[:introduction]
    @cta = opts[:cta]
    @jifiti_order = opts[:jifiti_order]
    @bcc = [ops_support_email].compact

    subject = mail_subject(opts[:subject_text], opts[:resend])
    mail(to: opts[:email], bcc: @bcc, from: Spree::Store.default.mail_from_address, subject: subject)
  end

  def default_options(order, resend)
    {
      resend: resend,
      email: order.email,
      subject_text: I18n.t('spree.mail.order_confirmation.subject', order_number: order.number),
      introduction: {
        user_name: user_name(order),
        heading: I18n.t('spree.mail.order_confirmation.heading'),
        content: I18n.t('spree.mail.order_confirmation.introduction', number_of_shipments: order.shipments.length),
        image: I18n.t('spree.mail.order_confirmation.image')
      },
      cta: { label: 'View Order', url: mail_url(order_url(order)) }
    }
  end

  def jifiti_options(order)
    order = Jifiti::OrderPresenter.new(order)
    return {} unless order.jifiti?

    {
      jifiti_order: true, email: order.buyer_email,
      subject_text: I18n.t('spree.mail.order_confirmation_jifiti.subject', order_number: order.number),
      introduction: {

        user_name: order.buyer_name,
        heading: I18n.t('spree.mail.order_confirmation_jifiti.heading'),
        content: I18n.t('spree.mail.order_confirmation_jifiti.introduction'),
        image: I18n.t('spree.mail.order_confirmation.image')
      }, cta: false
    }
  end

  def user_name(order)
    (order.user.blank? ? order.bill_address.firstname : order.user.first_name) || greet_name
  end

  def ops_support_email
    Maisonette::Config.fetch('mail.ops_support_email') if @order.line_items.detect(&:gift_card?)
  end
end
