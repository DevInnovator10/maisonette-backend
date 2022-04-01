# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = Maisonette::Config.fetch('sentry.dsn')
  config.server_name = Maisonette::Config.fetch('sentry.server_name')
  config.traces_sample_rate = Rails.configuration.x.sentry.traces_sample_rate
  config.send_default_pii = true
  config.breadcrumbs_logger = [:sentry_logger, :http_logger]

  config.before_send = lambda do |event, hint|
    if event.is_a?(Sentry::Event) && !event.tags[:skip_extra_context]
      event.extra.merge!(extra_info: sentry_context_info(event))
    end

    Rails.logger.error(Maisonette::Sentry.error_message(event, hint))

    event
  rescue StandardError => e
    Sentry.capture_exception_with_message(e, tags: { skip_extra_context: true })
    event
  end
end

SENTRY_CONTEXT_INFO = {
  '@current_api_user': {
    type: 'Spree::User',
    fields: %i[id]
  },
  '@inventory_unit': {
    type: 'Spree::InventoryUnit',
    fields: %i[id state variant_id shipment_id line_item_id]
  },
  '@line_item': {
    type: 'Spree::LineItem',
    fields: %i[id variant_id order_id quantity price]
  },
  '@order': {
    type: 'Spree::Order',
    fields: %i[number state shipment_state payment_state completed_at]
  },
  '@promotion': {
    type: 'Spree::Promotion',
    fields: %i[id description name promotion_category_id]
  },
  '@shipment': {
    type: 'Spree::Shipment',
    fields: %i[id tracking number cost state order_id]
  },
  '@user': {
    type: 'Spree::User',
    fields: %i[id]
  }
}.freeze

def sentry_context_info(event)
  event.instance_variables.map do |var|
    next unless SENTRY_CONTEXT_INFO.include? var

    get_var = event.instance_variable_get var
    next unless get_var.is_a? SENTRY_CONTEXT_INFO[var][:type].constantize

    [var, get_var.slice(SENTRY_CONTEXT_INFO[var][:fields])]
  end.compact.to_h
end
