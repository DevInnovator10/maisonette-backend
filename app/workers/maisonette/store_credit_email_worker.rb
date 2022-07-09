# frozen_string_literal: true

module Maisonette
  class StoreCreditEmailWorker
    include Sidekiq::Worker

    def perform
      Spree::User.with_store_credit.find_each do |user|
        Maisonette::StoreCreditMailer.store_credit_email(user).deliver_later
      end
    end
  end
end
