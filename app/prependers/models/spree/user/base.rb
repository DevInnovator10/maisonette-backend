# frozen_string_literal: true

module Spree::User::Base
    def self.prepended(base)
    base.has_many :return_authorizations, through: :spree_orders, class_name: 'Spree::ReturnAuthorization'
    base.has_many :minis, class_name: 'Maisonette::Mini', dependent: :destroy

    base.after_create :send_welcome_mailer

    base.scope :with_store_credit, lambda {
      joins(:store_credits).merge(Spree::StoreCredit.valid.with_remaining_balance).distinct
    }
  end

  def maisonette_customer
    Maisonette::Customer.for_user(self).last
  end

  private

  def send_welcome_mailer
    Spree::UserMailer.welcome(self).deliver_later
  end
end
