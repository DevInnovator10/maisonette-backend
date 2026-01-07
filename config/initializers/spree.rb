# frozen_string_literal: true

# Configure Solidus Preferences
# See http://docs.solidus.io/Spree/AppConfiguration.html for details

Spree.config do |config| # rubocop:disable Metrics/BlockLength
  # Core:

  # Default currency for new sites
  config.currency = 'USD'

  # from address for transactional emails
  config.mails_from = 'store@example.com'

  # Use legacy Spree::Order state machine
  config.use_legacy_order_state_machine = false

  # Use the legacy address' state validation logic
  config.use_legacy_address_state_validator = false

  # Uncomment to stop tracking inventory levels in the application
  # config.track_inventory_levels = false

  # When set, product caches are only invalidated when they fall below or rise
  # above the inventory_cache_threshold that is set. Default is to invalidate cache on
  # any inventory changes.
  # config.inventory_cache_threshold = 3

  # Disable legacy Solidus custom CanCanCan actions aliases
  config.use_custom_cancancan_actions = false

  # Defaults

  # Set this configuration to `true` to raise an exception when
  # an order is populated with a line item with a mismatching
  # currency. The `false` value will just add a validation error
  # and will be the only behavior accepted in future versions.
  # See https://github.com/solidusio/solidus/pull/3456 for more info.
  config.raise_with_invalid_currency = false

  # Frontend:

  # Custom logo for the frontend
  # config.logo = "logo/solidus_logo.png"

  # Template to use when rendering layout
  # config.layout = "spree/layouts/spree_application"

  # Admin:

  # Custom logo for the admin
  config.admin_interface_logo = 'logo/maisonette-wordmark.svg'

  # Gateway credentials can be configured statically here and referenced from
  # the admin. They can also be fully configured from the admin.
  #
  # config.static_model_preferences.add(
  #   Spree::Gateway::StripeGateway,
  #   'stripe_env_credentials',
  #   secret_key: ENV['STRIPE_SECRET_KEY'],
  #   publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
  #   server: Rails.env.production? ? 'production' : 'test',
  #   test_mode: !Rails.env.production?
  # )

  config.static_model_preferences.add(
    SolidusPaypalBraintree::Gateway,
    'braintree_credentials',
    environment: Maisonette::Config.fetch('braintree.environment'),
    merchant_id: Maisonette::Config.fetch('braintree.merchant_id'),
    public_key: Maisonette::Config.fetch('braintree.public_key'),
    private_key: Maisonette::Config.fetch('braintree.private_key'),
    paypal_flow: 'checkout'
  )

  config.static_model_preferences.add(
    Migration::LegacyGateway,
    'braintree_credentials',
    environment: Maisonette::Config.fetch('braintree.environment'),
    merchant_id: Maisonette::Config.fetch('braintree.merchant_id'),
    public_key: Maisonette::Config.fetch('braintree.public_key'),
    private_key: Maisonette::Config.fetch('braintree.private_key'),
    paypal_flow: 'vault'
  )

  config.static_model_preferences.add(
    SolidusAfterpay::PaymentMethod,
    'afterpay_credentials',
    test_mode: Maisonette::Config.fetch('afterpay.test_mode'),
    merchant_id: Maisonette::Config.fetch('afterpay.merchant_id'),
    secret_key: Maisonette::Config.fetch('afterpay.secret_key')
  )

  config.roles.assign_permissions :default, ['Spree::PermissionSets::WishlistManagement']
  config.roles.assign_permissions :default, ['Spree::PermissionSets::MinisManagement']
  config.roles.assign_permissions :default, ['Spree::PermissionSets::GiftwrapsManagement']
  config.roles.assign_permissions :default, ['Spree::PermissionSets::SitemapManagement']
  config.roles.assign_permissions :default, ['Spree::PermissionSets::SubscribersManagement']
  config.roles.assign_permissions :default, ['Spree::PermissionSets::EasyPostWebhookManagement']

  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::OrderManagement']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::ProductDisplay']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::VariantDisplay']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::MarketplaceDisplay']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::PromotionManagement']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::GiftCardManagement']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::StockDisplay']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::UserManagement']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::MiraklDisplay']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::NarvarDisplay']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::MarkDownDisplay']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::MigrationLogDisplay']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::EasypostDisplay']
  config.roles.assign_permissions :customer_care, ['Spree::PermissionSets::BraintreeDisputeDisplay']

  config.roles.assign_permissions :customer_care_admin, config.roles.roles['customer_care'].permission_sets
  config.roles.assign_permissions :customer_care_admin, ['Spree::PermissionSets::UserRoleManagement']

  config.roles.assign_permissions :merch, ['Spree::PermissionSets::OrderDisplay']
  config.roles.assign_permissions :merch, ['Spree::PermissionSets::ProductDisplay']
  config.roles.assign_permissions :merch, ['Spree::PermissionSets::VariantDisplay']
  config.roles.assign_permissions :merch, ['Spree::PermissionSets::StockDisplay']
  config.roles.assign_permissions :merch, ['Spree::PermissionSets::UserDisplay']
  config.roles.assign_permissions :merch, ['Spree::PermissionSets::MarketplaceDisplay']
  config.roles.assign_permissions :merch, ['Spree::PermissionSets::PromotionManagement']
  config.roles.assign_permissions :merch, ['Spree::PermissionSets::MarkDownManagement']
  config.roles.assign_permissions :merch, ['Spree::PermissionSets::MigrationLogDisplay']
  config.roles.assign_permissions :merch, ['Spree::PermissionSets::SalsifyDisplay']
  config.roles.assign_permissions :merch, ['Spree::PermissionSets::MaisonetteSaleManagement']

  config.roles.assign_permissions :merch_admin, config.roles.roles['merch'].permission_sets
  config.roles.assign_permissions :merch_admin, ['Spree::PermissionSets::UserRoleManagement']
  config.roles.assign_permissions :merch_admin, ['Spree::PermissionSets::UserManagement']
  config.roles.assign_permissions :merch_admin, ['Spree::PermissionSets::TaxonomyManagement']
  config.roles.assign_permissions :merch_admin, ['Spree::PermissionSets::MiraklDeleteProducts']
  config.roles.assign_permissions :merch_admin, ['Spree::PermissionSets::PriceScraperManagement']

  config.roles.assign_permissions :oms, ['Spree::PermissionSets::OmsManagement']
  config.roles.assign_permissions :oms_backend, ['Spree::PermissionSets::OmsAdminManagement']
end

Spree::Api::Config.configure do |config|
  config.requires_authentication = false
end

Spree::Config.generate_api_key_for_all_roles = true

Spree::Config.require_master_price = false

Spree.user_class = 'Spree::LegacyUser'

Spree::Config.variant_price_selector_class = Maisonette::Variant::PriceSelector

Spree::PermittedAttributes.checkout_attributes.push :is_gift, :gift_message, :gift_email, :use_store_credits,
                                                    :last_ip_address, :channel,
                                                    forter_connection_info: [:id, :user_agent, :token]
Spree::PermittedAttributes.line_item_attributes.push options: [:vendor_id, gift_card_details: [
  :recipient_name, :recipient_email, :purchaser_name, :gift_message
]]
Spree::PermittedAttributes.product_attributes.delete :shipping_category_id
Spree::PermittedAttributes.product_attributes.delete :shipping_category_id
Spree::PermittedAttributes.source_attributes.push :braintree_payment_source_id, :reusable
Spree::PermittedAttributes.taxon_attributes.push :hidden, :highlight, :header_link, :url_override, :add_flair,
                                                 :track_insights, :view_all_url_override, :google_product_category
Spree::PermittedAttributes.user_attributes.push :first_name, :last_name, :current_password
Spree::PermittedAttributes.return_authorization_attributes.push :gift_recipient_email,
                                                                easypost_tracker: [:id, :tracking_code, :carrier]
Spree::PermittedAttributes.shipment_attributes.push(
  giftwrap_attributes: [:_destroy, :id]
)
Spree::PermittedAttributes.taxon_attributes.push(:short_description)

Spree::Config.promotion_chooser_class = 'Maisonette::PromotionChooser'

Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::ExcludedProduct
Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::ExcludedTaxon
Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::RestrictShipping
Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::RestrictShippingItemTotal
Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::NthOrderByEmail
Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::AtLeastNOrders

Rails.application.config.spree.promotions.actions << Spree::Promotion::Actions::GroupShipping
Rails.application.config.spree.promotions.actions << Spree::Promotion::Actions::FreeFlatRateAmountShipping
Rails.application.config.spree.promotions.actions << Spree::Promotion::Actions::FreeShippingPerShipment
Rails.application.config.spree.promotions.actions << Spree::Promotion::Actions::DetractOtherShippingCost

Rails.application.config.spree.promotions.shipping_actions << Spree::Promotion::Actions::GroupShipping
Rails.application.config.spree.promotions.shipping_actions << Spree::Promotion::Actions::FreeFlatRateAmountShipping
Rails.application.config.spree.promotions.shipping_actions << Spree::Promotion::Actions::FreeShippingPerShipment
Rails.application.config.spree.promotions.shipping_actions << Spree::Promotion::Actions::DetractOtherShippingCost

Rails.application.config.spree.promotions.actions << Spree::Promotion::Actions::CreateGiftCardTransaction

Rails.application.config.spree.payment_methods << Jifiti::JifitiGateway

Spree::Config.stock.coordinator_class = 'Spree::Stock::MarketplaceCoordinator'

Spree::Config.auto_capture = true

Spree::Config.environment.stock_splitters = [Spree::Stock::Splitter::SharedShippingMethod,
                                             Spree::Stock::Splitter::Backordered]

Spree::Config.order_number_generator = Spree::Order::NumberGenerator.new(prefix: 'M')

Spree::Reimbursement.reimbursement_models << Spree::Reimbursement::GiftCard

Spree::Config.events.autoload_subscribers = false

Spree::Event.subscriber_registry.activate_subscriber(OrderManagement::OrderFinalizedSubscriber)
Spree::Event.subscriber_registry.activate_subscriber(OrderManagement::MiraklOrderStateChangedSubscriber)
Spree::Event.subscriber_registry.activate_subscriber(OrderManagement::MiraklOrderShippingInfoChangedSubscriber)
Spree::Event.subscriber_registry.activate_subscriber(OrderManagement::EasypostTrackerShippedSubscriber)
Spree::Event.subscriber_registry.activate_subscriber(OrderManagement::OrderShippedSubscriber)
Spree::Event.subscriber_registry.activate_subscriber(Spree::GiftNotificationSubscriber)
Spree::Event.subscriber_registry.activate_subscriber(Easypost::SaveEasypostAddressSubscriber)

Spree::Config.require_payment_to_ship = false

Spree::Address.state_validator_class = Maisonette::Address::StateValidator

Spree::Config.billing_address_required = true
