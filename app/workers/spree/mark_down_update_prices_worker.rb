# frozen_string_literal: true

module Spree
  class MarkDownUpdatePricesWorker
    include Sidekiq::Worker

    sidekiq_options lock: :while_executing, retry: false

    def perform(mark_down_id)
      @mark_down_id = mark_down_id
      result = ::MarkDown::UpdateOnSaleInteractor.call(mark_down: mark_down)
      if result.failure?
        Sentry.capture_exception_with_message(Spree::UpdatePricesException.new(I18n.t("spree.#{result.message}")))
        send_updated_error_email
      else
        mark_down.update_sale_prices_cost_price(mark_down.sale_prices)
        send_updated_email
      end
    end

    private

    def mark_down
      @mark_down ||= Spree::MarkDown.find(@mark_down_id)
    end

    def send_updated_email
      Spree::MarkDownUpdatePricesMailer.send_updated_email(mark_down.title).deliver_later
    end

    def send_updated_error_email
      Spree::MarkDownUpdatePricesMailer.send_updated_error_email(mark_down.title).deliver_later
    end
  end
end

class Spree::UpdatePricesException < StandardError; end # rubocop:disable Style/ClassAndModuleChildren
