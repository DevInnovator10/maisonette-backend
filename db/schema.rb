# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_11_01_120724) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "easypost_orders", force: :cascade do |t|
    t.bigint "spree_shipment_id"
    t.string "easypost_id"
    t.string "tracking_code"
    t.string "rate_service"
    t.string "rate_carrier"
    t.string "easypost_api_key"
    t.decimal "rate", precision: 8, scale: 2
    t.boolean "is_return", default: false
    t.integer "delivery_days"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spree_shipment_id"], name: "index_easypost_orders_on_spree_shipment_id"
  end

  create_table "easypost_parcels", force: :cascade do |t|
    t.string "easypost_id"
    t.decimal "length", precision: 8, scale: 2
    t.decimal "width", precision: 8, scale: 2
    t.decimal "height", precision: 8, scale: 2
    t.decimal "weight", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "easypost_reports", force: :cascade do |t|
    t.string "report_type", null: false
    t.string "report_type_id", null: false
    t.string "status", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["end_date"], name: "index_easypost_reports_on_end_date", order: :desc
  end

  create_table "easypost_shipments", force: :cascade do |t|
    t.bigint "easypost_order_id"
    t.bigint "easypost_parcel_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["easypost_order_id"], name: "index_easypost_shipments_on_easypost_order_id"
    t.index ["easypost_parcel_id"], name: "index_easypost_shipments_on_easypost_parcel_id"
  end

  create_table "easypost_trackers", force: :cascade do |t|
    t.bigint "easypost_order_id"
    t.text "webhook_payload"
    t.string "tracking_code"
    t.string "carrier"
    t.datetime "date_shipped"
    t.datetime "date_delivered"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "date_out_for_delivery"
    t.string "status"
    t.text "fees"
    t.datetime "est_delivery_date"
    t.bigint "spree_return_authorization_id"
    t.index ["carrier"], name: "index_easypost_trackers_on_carrier"
    t.index ["easypost_order_id"], name: "index_easypost_trackers_on_easypost_order_id"
    t.index ["spree_return_authorization_id"], name: "index_easypost_trackers_on_spree_return_authorization_id"
    t.index ["tracking_code"], name: "index_easypost_trackers_on_tracking_code", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "maisonette_customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "maisonette_fees", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.integer "fee_type"
    t.bigint "spree_return_authorization_id"
    t.bigint "spree_reimbursement_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["spree_reimbursement_id"], name: "index_maisonette_fees_on_spree_reimbursement_id"
    t.index ["spree_return_authorization_id"], name: "index_maisonette_fees_on_spree_return_authorization_id"
  end

  create_table "maisonette_giftwraps", force: :cascade do |t|
    t.bigint "stock_location_id"
    t.bigint "shipment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "order_id"
    t.string "shipping_method_ids"
    t.index ["order_id", "stock_location_id", "shipping_method_ids", "shipment_id"], name: "index_maisonette_giftwraps_order_stock_location_shipping_method"
    t.index ["order_id"], name: "index_maisonette_giftwraps_on_order_id"
    t.index ["shipment_id"], name: "index_maisonette_giftwraps_on_shipment_id"
    t.index ["stock_location_id"], name: "index_maisonette_giftwraps_on_stock_location_id"
  end

  create_table "maisonette_kustomer_entities", force: :cascade do |t|
    t.string "kustomerable_type"
    t.bigint "kustomerable_id"
    t.string "type"
    t.integer "sync_status"
    t.string "last_request_payload"
    t.integer "last_result"
    t.string "last_message"
    t.string "last_response_body"
    t.string "last_response_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kustomerable_type", "kustomerable_id"], name: "index_kustomer_entities_kustomerable"
  end

  create_table "maisonette_minis", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name"
    t.integer "birth_month"
    t.integer "birth_day"
    t.integer "birth_year", null: false
    t.boolean "gender_boy", default: true
    t.boolean "gender_girl", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "calculated_birthday"
    t.index ["user_id"], name: "index_maisonette_minis_on_user_id"
  end

  create_table "maisonette_price_scraper_categories", force: :cascade do |t|
    t.bigint "taxon_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["taxon_id"], name: "index_price_scraper_categories_on_taxon_id"
  end

  create_table "maisonette_products_promotions", id: false, force: :cascade do |t|
    t.bigint "spree_product_id", null: false
    t.bigint "spree_promotion_id", null: false
    t.index ["spree_product_id"], name: "index_maisonette_products_promotions_on_spree_product_id"
    t.index ["spree_promotion_id"], name: "index_maisonette_products_promotions_on_spree_promotion_id"
  end

  create_table "maisonette_sale_sku_configurations", force: :cascade do |t|
    t.bigint "sale_id", null: false
    t.bigint "offer_settings_id", null: false
    t.bigint "sale_price_id"
    t.decimal "percent_off"
    t.decimal "maisonette_liability"
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean "final_sale"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.decimal "static_sale_price", precision: 10, scale: 2
    t.decimal "static_cost_price", precision: 10, scale: 2
    t.index ["created_by_id"], name: "index_maisonette_sale_sku_configurations_on_created_by_id"
    t.index ["offer_settings_id"], name: "index_maisonette_sale_sku_configurations_on_offer_settings_id"
    t.index ["sale_id"], name: "index_maisonette_sale_sku_configurations_on_sale_id"
    t.index ["updated_by_id"], name: "index_maisonette_sale_sku_configurations_on_updated_by_id"
  end

  create_table "maisonette_sales", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "percent_off", null: false
    t.decimal "maisonette_liability", null: false
    t.datetime "start_date", null: false
    t.datetime "end_date"
    t.boolean "final_sale"
    t.boolean "permanent"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "taxon_id"
    t.index ["taxon_id"], name: "index_maisonette_sales_on_taxon_id"
  end

  create_table "maisonette_shipping_invoices", force: :cascade do |t|
    t.bigint "easypost_order_id"
    t.float "amount"
    t.float "weight"
    t.string "weight_unit"
    t.string "order_number"
    t.string "invoice_number"
    t.string "billing_account"
    t.string "tracking_code"
    t.string "carrier"
    t.datetime "transaction_date"
    t.string "internal_reference"
    t.string "sender_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "invoice_date"
    t.float "adjustment_amount"
    t.index ["easypost_order_id"], name: "index_maisonette_shipping_invoices_on_easypost_order_id"
    t.index ["order_number"], name: "index_maisonette_shipping_invoices_on_order_number"
    t.index ["tracking_code"], name: "index_maisonette_shipping_invoices_on_tracking_code"
  end

  create_table "maisonette_stock_requests", force: :cascade do |t|
    t.string "email"
    t.string "state"
    t.bigint "variant_id"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["variant_id"], name: "index_maisonette_stock_requests_on_variant_id"
  end

  create_table "maisonette_subscribers", force: :cascade do |t|
    t.bigint "user_id"
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "source"
    t.integer "status", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.string "list_id"
    t.string "klaviyo_id"
    t.index ["email", "list_id"], name: "index_maisonette_subscribers_on_email_and_list_id", unique: true
    t.index ["user_id"], name: "index_maisonette_subscribers_on_user_id"
  end

  create_table "maisonette_user_data_deletion_requests", force: :cascade do |t|
    t.integer "status", default: 1, null: false
    t.string "email", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_maisonette_user_data_deletion_requests_on_user_id", unique: true
  end

  create_table "maisonette_variant_group_attributes", force: :cascade do |t|
    t.bigint "option_value_id", null: false
    t.bigint "product_id", null: false
    t.text "description"
    t.string "meta_description"
    t.string "meta_title"
    t.string "meta_keywords"
    t.string "salsify_parent_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "sku"
    t.datetime "available_on"
    t.datetime "available_until"
    t.index ["option_value_id"], name: "index_variant_group_attributes_on_option_value_id"
    t.index ["product_id"], name: "index_variant_group_attributes_on_product_id"
  end

  create_table "migration_logs", force: :cascade do |t|
    t.integer "status", default: 1, null: false
    t.bigint "legacy_id"
    t.bigint "migrable_id"
    t.string "migrable_type", null: false
    t.bigint "migration_log_id"
    t.string "order_number"
    t.text "extra"
    t.text "messages"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "migrated_type"
    t.bigint "migrated_id"
    t.index ["migrated_type", "migrated_id"], name: "index_migration_logs_on_migrated_type_and_migrated_id"
  end

  create_table "mirakl_business_intelligences", force: :cascade do |t|
    t.string "commercial_id"
    t.string "order_id"
    t.string "order_line_id"
    t.string "order_line_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "date_created"
    t.datetime "date_waiting_acceptance"
    t.datetime "date_waiting_debit"
    t.datetime "date_waiting_debit_payment"
    t.datetime "date_shipping"
    t.datetime "date_shipped"
    t.datetime "date_received"
    t.datetime "date_paid"
    t.datetime "debit_transaction_date"
    t.integer "debit_transaction_number"
    t.datetime "date_incident_open"
    t.datetime "date_incident_close"
    t.string "incident_reason_code"
    t.text "incident_reason_label"
    t.datetime "date_waiting_refund"
    t.datetime "date_waiting_refund_payment"
    t.datetime "date_refunded"
    t.integer "refund_reason_code"
    t.text "refund_reason_label"
    t.datetime "refund_transaction_date"
    t.integer "refund_transaction_number"
    t.integer "quantity"
    t.decimal "price_unit"
    t.decimal "price"
    t.decimal "shipping_price"
    t.decimal "commission_fee"
    t.decimal "commission_vat"
    t.decimal "commission_rate_vat"
    t.decimal "total_commission"
    t.string "commission_grid_label"
    t.string "payment_type"
    t.string "shipping_type_code"
    t.text "shipping_type_label"
    t.string "shipping_zone_code"
    t.string "shipping_zone_label"
    t.integer "shop_id"
    t.integer "shop_operator_internal_id"
    t.string "shop_name"
    t.string "shop_is_professional"
    t.decimal "shop_reward"
    t.string "product_sku"
    t.string "product_title"
    t.string "category_code"
    t.string "category_label"
    t.integer "offer_id"
    t.string "offer_sku"
    t.integer "offer_state_code"
    t.string "offer_state_label"
    t.string "customer_id"
    t.string "customer_lastname"
    t.string "customer_firstname"
    t.string "customer_civility"
    t.string "customer_email"
    t.string "customer_shipping_civility"
    t.string "customer_shipping_lastname"
    t.string "customer_shipping_firstname"
    t.string "customer_shipping_company"
    t.string "customer_shipping_street1"
    t.string "customer_shipping_street2"
    t.string "customer_shipping_complementary"
    t.string "customer_shipping_zip_code"
    t.string "customer_shipping_state"
    t.string "customer_shipping_city"
    t.string "customer_shipping_country"
    t.string "customer_shipping_phone"
    t.string "customer_shipping_phone_secondary"
    t.text "customer_shipping_additional_info"
    t.text "customer_shipping_internal_additional_info"
    t.string "customer_billing_civility"
    t.string "customer_billing_lastname"
    t.string "customer_billing_firstname"
    t.string "customer_billing_company"
    t.string "customer_billing_street1"
    t.string "customer_billing_street2"
    t.string "customer_billing_complementary"
    t.string "customer_billing_zip_code"
    t.string "customer_billing_state"
    t.string "customer_billing_city"
    t.string "customer_billing_country"
    t.string "customer_billing_phone"
    t.string "customer_billing_phone_secondary"
    t.string "payment_state_code"
    t.integer "invoice_number"
    t.text "additional_fields"
    t.text "order_additional_fields"
    t.decimal "refunds"
    t.decimal "price_taxes"
    t.decimal "shipping_price_taxes"
    t.string "currency_iso_code"
    t.text "commission_taxes"
    t.string "customer_locale"
    t.string "carrier_code"
    t.string "carrier_name"
    t.string "tracking_url"
    t.string "tracking_number"
    t.string "order_channel_code"
    t.string "order_channel_label"
    t.string "order_payment_workflow"
    t.datetime "order_customer_debited_date"
    t.string "brand"
    t.text "cancelations"
    t.integer "quote_id"
    t.string "promotions"
    t.string "payment_duration"
    t.string "product_shop_sku"
    t.integer "original_offer_leadtime_to_ship"
    t.integer "order_leadtime_to_ship"
    t.index ["carrier_code"], name: "index_mirakl_business_intelligences_on_carrier_code"
    t.index ["carrier_name"], name: "index_mirakl_business_intelligences_on_carrier_name"
    t.index ["commercial_id"], name: "index_mirakl_business_intelligences_on_commercial_id"
    t.index ["order_id"], name: "index_mirakl_business_intelligences_on_order_id"
    t.index ["order_line_id"], name: "index_mirakl_business_intelligences_on_order_line_id", unique: true
    t.index ["tracking_number"], name: "index_mirakl_business_intelligences_on_tracking_number"
  end

  create_table "mirakl_commercial_orders", force: :cascade do |t|
    t.bigint "spree_order_id"
    t.string "commercial_order_id"
    t.string "state"
    t.string "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spree_order_id"], name: "index_mirakl_commercial_orders_on_spree_order_id"
  end

  create_table "mirakl_invoices", force: :cascade do |t|
    t.string "invoice_id"
    t.boolean "issued", default: false
    t.integer "invoice_type"
    t.bigint "mirakl_shop_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "doc_number"
    t.index ["invoice_id"], name: "index_mirakl_invoices_on_invoice_id"
    t.index ["mirakl_shop_id"], name: "index_mirakl_invoices_on_mirakl_shop_id"
  end

  create_table "mirakl_offers", force: :cascade do |t|
    t.integer "offer_id", null: false
    t.integer "shop_id", null: false
    t.integer "quantity"
    t.string "sku"
    t.string "offer_state"
    t.boolean "active"
    t.boolean "best", default: false, null: false
    t.decimal "original_price"
    t.decimal "price"
    t.datetime "available_to"
    t.datetime "available_from"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "spree_price_id"
    t.string "shop_sku"
    t.index ["offer_id"], name: "index_mirakl_offers_on_offer_id"
    t.index ["shop_id"], name: "index_mirakl_offers_on_shop_id"
    t.index ["sku"], name: "index_mirakl_offers_on_sku"
    t.index ["spree_price_id"], name: "index_mirakl_offers_on_spree_price_id"
  end

  create_table "mirakl_order_line_reimbursements", force: :cascade do |t|
    t.decimal "amount", precision: 8, scale: 2
    t.decimal "tax", precision: 8, scale: 2
    t.decimal "commission_amount", precision: 8, scale: 2
    t.decimal "commission_tax", precision: 8, scale: 2
    t.decimal "shipping_amount", precision: 8, scale: 2
    t.decimal "shipping_tax", precision: 8, scale: 2
    t.decimal "total", precision: 8, scale: 2
    t.integer "quantity"
    t.integer "refund_reason_id"
    t.integer "order_line_id"
    t.string "state"
    t.integer "mirakl_type"
    t.string "mirakl_reimbursement_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "mirakl_total", precision: 8, scale: 2
    t.datetime "refund_processing_sent_at"
    t.bigint "reimbursement_id"
    t.index ["mirakl_reimbursement_id", "mirakl_type"], name: "index_mirakl_order_line_reimbs_on_reimb_id_and_mirakl_type"
    t.index ["reimbursement_id"], name: "index_mirakl_order_line_reimbursements_on_reimbursement_id"
  end

  create_table "mirakl_order_lines", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "line_item_id", null: false
    t.string "mirakl_order_line_id", null: false
    t.integer "return_authorization_id"
    t.decimal "commission_fee", precision: 8, scale: 2
    t.string "state"
    t.float "vendor_mark_down_credit_total"
    t.float "vendor_mark_down_credit_amount"
    t.float "cost_price_fee_total"
    t.float "cost_price_fee_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "return_fee", default: 0.0
    t.index ["line_item_id"], name: "index_mirakl_order_lines_on_line_item_id"
    t.index ["order_id"], name: "index_mirakl_order_lines_on_order_id"
    t.index ["return_authorization_id"], name: "index_mirakl_order_lines_on_return_authorization_id"
  end

  create_table "mirakl_orders", force: :cascade do |t|
    t.string "state"
    t.string "logistic_order_id"
    t.bigint "commercial_order_id"
    t.bigint "shipment_id"
    t.float "late_shipping_fee", default: 0.0
    t.float "no_stock_fee", default: 0.0
    t.float "return_label_fee"
    t.boolean "invoiced", default: false
    t.boolean "incident", default: false
    t.datetime "invoicing_date"
    t.jsonb "mirakl_payload", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "order_fee"
    t.string "shipping_tracking"
    t.string "shipping_carrier_code"
    t.datetime "acceptance_decision_date"
    t.boolean "bulk_document_sent", default: false
    t.boolean "bulk_document_error_sent", default: false
    t.datetime "last_updated_date"
    t.integer "shop_id"
    t.index ["commercial_order_id"], name: "index_mirakl_orders_on_commercial_order_id"
    t.index ["shipment_id"], name: "index_mirakl_orders_on_shipment_id"
    t.index ["shop_id"], name: "index_mirakl_orders_on_shop_id"
  end

  create_table "mirakl_shops", force: :cascade do |t|
    t.integer "shop_id", null: false
    t.integer "shop_status"
    t.integer "compliance_violation_fee_type"
    t.integer "lead_time_ship_leniency", default: 0
    t.float "compliance_violation_fee", default: 0.0
    t.float "transaction_fee_percentage", default: 0.0
    t.float "gift_wrap_fee", default: 0.0
    t.float "dropship_surcharge", default: 0.0
    t.string "name"
    t.string "tax_id_number"
    t.string "easypost_api_key"
    t.string "working_hr_start_time", default: "800"
    t.string "fulfil_by_eod_cutoff_time", default: "1400"
    t.boolean "generate_returns_label", default: true
    t.boolean "manage_own_shipping", default: false
    t.boolean "cost_price", default: false
    t.boolean "tx_fee_24hr_ship_waiver", default: false
    t.boolean "send_shipping_cost", default: false
    t.boolean "premium", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "order_fee_parcel"
    t.decimal "order_fee_freight"
    t.text "shipping_carriers"
    t.boolean "generate_bulk_document", default: false
    t.string "email"
    t.boolean "cartonize_shipments", default: false
    t.text "box_sizes"
    t.text "expedited_shipping_carriers"
    t.decimal "shop_return_fee", default: "0.0"
    t.index ["shop_id"], name: "index_mirakl_shops_on_shop_id"
  end

  create_table "mirakl_updates", force: :cascade do |t|
    t.integer "mirakl_type"
    t.datetime "started_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["started_at"], name: "index_mirakl_updates_on_started_at", order: :desc
  end

  create_table "mirakl_warehouses", force: :cascade do |t|
    t.bigint "mirakl_shop_id"
    t.bigint "address_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_mirakl_warehouses_on_address_id"
    t.index ["mirakl_shop_id"], name: "index_mirakl_warehouses_on_mirakl_shop_id"
  end

  create_table "narvar_orders", force: :cascade do |t|
    t.integer "spree_order_id"
    t.string "state"
    t.integer "result_code"
    t.text "error_messages"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spree_order_id"], name: "index_narvar_orders_on_spree_order_id"
  end

  create_table "order_management_appeasement_reasons", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true
    t.string "code"
    t.boolean "mutable", default: true
    t.string "mirakl_code", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "order_management_cancellation_reasons", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true
    t.string "code"
    t.boolean "mutable", default: true
    t.string "mirakl_code", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "order_management_entities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "order_manageable_type"
    t.string "order_manageable_id"
    t.string "type"
    t.string "order_management_entity_ref"
    t.integer "sync_status", default: 1, null: false
    t.integer "last_result"
    t.string "last_message"
    t.string "last_response_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "parent_id"
    t.jsonb "last_request_payload", default: {}
    t.index ["order_manageable_type", "order_manageable_id"], name: "index_order_management_entities_order_manageable"
    t.index ["order_manageable_type"], name: "index_order_management_entities_on_order_manageable_type"
  end

  create_table "order_management_oms_commands", force: :cascade do |t|
    t.integer "state", default: 1, null: false
    t.integer "fail_count"
    t.string "type"
    t.string "external_id"
    t.string "order_management_ref"
    t.text "last_message"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "last_request_payload", default: {}
    t.jsonb "data", default: {}
    t.index ["discarded_at"], name: "index_order_management_oms_commands_on_discarded_at"
  end

  create_table "order_management_order_item_summaries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "sales_order_id"
    t.string "order_management_ref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "summarable_type"
    t.bigint "summarable_id"
    t.index ["sales_order_id"], name: "index_order_management_order_item_summaries_on_sales_order_id"
    t.index ["summarable_type", "summarable_id"], name: "index_order_management_item_summaries_on_summarable"
  end

  create_table "order_management_order_summaries", force: :cascade do |t|
    t.bigint "sales_order_id"
    t.string "order_management_ref"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["sales_order_id"], name: "index_order_management_order_summaries_on_sales_order_id"
  end

  create_table "order_management_sales_orders", force: :cascade do |t|
    t.bigint "spree_order_id"
    t.string "order_management_ref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "completed_at"
    t.jsonb "last_request_payload", default: {}
    t.index ["order_management_ref"], name: "index_order_management_sales_orders_on_order_management_ref"
    t.index ["spree_order_id"], name: "index_order_management_sales_orders_on_spree_order_id"
  end

  create_table "reporting_braintree_disputes", force: :cascade do |t|
    t.bigint "spree_payment_id"
    t.string "transaction_code"
    t.string "reason"
    t.string "kind"
    t.string "status"
    t.float "amount"
    t.string "case_number"
    t.string "braintree_dispute_id"
    t.string "dispute_payload"
    t.string "spree_order_number"
    t.datetime "received_date"
    t.index ["braintree_dispute_id"], name: "index_reporting_braintree_disputes_on_braintree_dispute_id"
    t.index ["case_number"], name: "index_reporting_braintree_disputes_on_case_number"
    t.index ["spree_order_number"], name: "index_reporting_braintree_disputes_on_spree_order_number"
    t.index ["spree_payment_id"], name: "index_reporting_braintree_disputes_on_spree_payment_id"
  end

  create_table "salsify_import_rows", force: :cascade do |t|
    t.bigint "salsify_import_id"
    t.bigint "spree_product_id"
    t.jsonb "data", default: {}, null: false
    t.text "messages"
    t.string "state", default: "created", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unique_key"
    t.index ["salsify_import_id"], name: "index_salsify_import_rows_on_salsify_import_id"
    t.index ["spree_product_id"], name: "index_salsify_import_rows_on_spree_product_id"
  end

  create_table "salsify_imports", force: :cascade do |t|
    t.string "file_to_import"
    t.string "state", default: "created", null: false
    t.text "messages"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "import_type", default: "", null: false
    t.datetime "notified_at"
  end

  create_table "salsify_mirakl_offer_export_jobs", force: :cascade do |t|
    t.integer "status", default: 10
    t.datetime "import_executed_at"
    t.datetime "import_finished_at"
    t.text "error_message"
    t.text "synchro_ids"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "salsify_mirakl_product_export_jobs", force: :cascade do |t|
    t.integer "status", default: 10
    t.datetime "import_executed_at"
    t.datetime "import_finished_at"
    t.text "error_message"
    t.integer "synchro_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "solidus_afterpay_payment_sources", id: :serial, force: :cascade do |t|
    t.string "token"
    t.integer "payment_method_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["payment_method_id"], name: "index_solidus_afterpay_payment_sources_on_payment_method_id"
  end

  create_table "solidus_paypal_braintree_configurations", id: :serial, force: :cascade do |t|
    t.boolean "paypal", default: false, null: false
    t.boolean "apple_pay", default: false, null: false
    t.integer "store_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "credit_card", default: false, null: false
    t.index ["store_id"], name: "index_solidus_paypal_braintree_configurations_on_store_id"
  end

  create_table "solidus_paypal_braintree_customers", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "braintree_customer_id"
    t.boolean "filled", default: true
    t.index ["braintree_customer_id"], name: "index_braintree_customers_on_braintree_customer_id", unique: true
    t.index ["user_id"], name: "index_braintree_customers_on_user_id", unique: true
  end

  create_table "solidus_paypal_braintree_sources", id: :serial, force: :cascade do |t|
    t.string "nonce"
    t.string "token"
    t.string "payment_type", null: false
    t.integer "user_id"
    t.integer "customer_id"
    t.integer "payment_method_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "reusable", default: true, null: false
    t.string "device_data"
    t.index ["customer_id"], name: "index_solidus_paypal_braintree_sources_on_customer_id"
    t.index ["payment_method_id"], name: "index_solidus_paypal_braintree_sources_on_payment_method_id"
    t.index ["user_id"], name: "index_solidus_paypal_braintree_sources_on_user_id"
  end

  create_table "spree_addresses", id: :serial, force: :cascade do |t|
    t.string "firstname"
    t.string "lastname"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "zipcode"
    t.string "phone"
    t.string "state_name"
    t.string "alternative_phone"
    t.string "company"
    t.integer "state_id"
    t.integer "country_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "easypost_address_id"
    t.boolean "residential"
    t.string "name"
    t.index ["country_id"], name: "index_spree_addresses_on_country_id"
    t.index ["firstname"], name: "index_addresses_on_firstname"
    t.index ["lastname"], name: "index_addresses_on_lastname"
    t.index ["name"], name: "index_spree_addresses_on_name"
    t.index ["state_id"], name: "index_spree_addresses_on_state_id"
  end

  create_table "spree_adjustment_reasons", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.boolean "active", default: true
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["active"], name: "index_spree_adjustment_reasons_on_active"
    t.index ["code"], name: "index_spree_adjustment_reasons_on_code"
  end

  create_table "spree_adjustments", id: :serial, force: :cascade do |t|
    t.string "source_type"
    t.integer "source_id"
    t.string "adjustable_type"
    t.integer "adjustable_id", null: false
    t.decimal "amount", precision: 10, scale: 2
    t.string "label"
    t.boolean "eligible", default: true
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.integer "order_id", null: false
    t.boolean "included", default: false
    t.integer "promotion_code_id"
    t.integer "adjustment_reason_id"
    t.boolean "finalized", default: false, null: false
    t.index ["adjustable_id", "adjustable_type"], name: "index_spree_adjustments_on_adjustable_id_and_adjustable_type"
    t.index ["adjustable_id"], name: "index_adjustments_on_order_id"
    t.index ["eligible"], name: "index_spree_adjustments_on_eligible"
    t.index ["order_id"], name: "index_spree_adjustments_on_order_id"
    t.index ["promotion_code_id"], name: "index_spree_adjustments_on_promotion_code_id"
    t.index ["source_id", "source_type"], name: "index_spree_adjustments_on_source_id_and_source_type"
  end

  create_table "spree_assets", id: :serial, force: :cascade do |t|
    t.string "viewable_type"
    t.integer "viewable_id"
    t.integer "attachment_width"
    t.integer "attachment_height"
    t.integer "attachment_file_size"
    t.integer "position"
    t.string "attachment_content_type"
    t.string "attachment_file_name"
    t.string "type", limit: 75
    t.datetime "attachment_updated_at"
    t.text "alt"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "source_url"
    t.bigint "maisonette_variant_group_attributes_id"
    t.index ["maisonette_variant_group_attributes_id"], name: "index_assets_variant_group_attributes"
    t.index ["viewable_id"], name: "index_assets_on_viewable_id"
    t.index ["viewable_type", "type"], name: "index_assets_on_viewable_type_and_type"
  end

  create_table "spree_avalara_entity_use_codes", id: :serial, force: :cascade do |t|
    t.string "use_code"
    t.string "use_code_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_avalara_transactions", id: :serial, force: :cascade do |t|
    t.integer "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_spree_avalara_transactions_on_order_id"
  end

  create_table "spree_calculators", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "calculable_type"
    t.integer "calculable_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.text "preferences"
    t.index ["calculable_id", "calculable_type"], name: "index_spree_calculators_on_calculable_id_and_calculable_type"
    t.index ["id", "type"], name: "index_spree_calculators_on_id_and_type"
  end

  create_table "spree_cartons", id: :serial, force: :cascade do |t|
    t.string "number"
    t.string "external_number"
    t.integer "stock_location_id"
    t.integer "address_id"
    t.integer "shipping_method_id"
    t.string "tracking"
    t.datetime "shipped_at"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.integer "imported_from_shipment_id"
    t.string "shipping_carrier_code"
    t.string "override_tracking_url"
    t.index ["external_number"], name: "index_spree_cartons_on_external_number"
    t.index ["imported_from_shipment_id"], name: "index_spree_cartons_on_imported_from_shipment_id", unique: true
    t.index ["number"], name: "index_spree_cartons_on_number", unique: true
    t.index ["stock_location_id"], name: "index_spree_cartons_on_stock_location_id"
  end

  create_table "spree_countries", id: :serial, force: :cascade do |t|
    t.string "iso_name"
    t.string "iso"
    t.string "iso3"
    t.string "name"
    t.integer "numcode"
    t.boolean "states_required", default: false
    t.datetime "updated_at", precision: 6
    t.datetime "created_at", precision: 6
    t.index ["iso"], name: "index_spree_countries_on_iso"
  end

  create_table "spree_credit_cards", id: :serial, force: :cascade do |t|
    t.string "month"
    t.string "year"
    t.string "cc_type"
    t.string "last_digits"
    t.string "gateway_customer_profile_id"
    t.string "gateway_payment_profile_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "name"
    t.integer "user_id"
    t.integer "payment_method_id"
    t.boolean "default", default: false, null: false
    t.integer "address_id"
    t.index ["payment_method_id"], name: "index_spree_credit_cards_on_payment_method_id"
    t.index ["user_id"], name: "index_spree_credit_cards_on_user_id"
  end

  create_table "spree_customer_returns", id: :serial, force: :cascade do |t|
    t.string "number"
    t.integer "stock_location_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
  end

  create_table "spree_gift_card_transactions", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "action"
    t.string "currency"
    t.bigint "gift_card_id"
    t.bigint "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gift_card_id"], name: "index_spree_gift_card_transactions_on_gift_card_id"
    t.index ["order_id"], name: "index_spree_gift_card_transactions_on_order_id"
  end

  create_table "spree_gift_cards", force: :cascade do |t|
    t.string "name"
    t.decimal "balance", precision: 10, scale: 2, default: "0.0"
    t.string "currency"
    t.decimal "original_amount", precision: 10, scale: 2, default: "0.0"
    t.bigint "promotion_code_id"
    t.bigint "line_item_id"
    t.string "state", default: "allocated", null: false
    t.string "recipient_email"
    t.string "recipient_name"
    t.string "purchaser_name"
    t.datetime "send_email_at"
    t.text "gift_message"
    t.boolean "redeemable", default: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at"
    t.datetime "starts_at"
    t.index ["line_item_id"], name: "index_spree_gift_cards_on_line_item_id"
    t.index ["promotion_code_id"], name: "index_spree_gift_cards_on_promotion_code_id"
  end

  create_table "spree_inventory_units", id: :serial, force: :cascade do |t|
    t.string "state"
    t.integer "variant_id"
    t.integer "shipment_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.boolean "pending", default: true
    t.integer "line_item_id"
    t.integer "carton_id"
    t.bigint "mirakl_order_line_reimbursement_id"
    t.index ["carton_id"], name: "index_spree_inventory_units_on_carton_id"
    t.index ["line_item_id"], name: "index_spree_inventory_units_on_line_item_id"
    t.index ["mirakl_order_line_reimbursement_id"], name: "index_spree_inventory_units_on_mirakl_order_line_reimb_id"
    t.index ["shipment_id"], name: "index_inventory_units_on_shipment_id"
    t.index ["variant_id"], name: "index_inventory_units_on_variant_id"
  end

  create_table "spree_line_item_actions", id: :serial, force: :cascade do |t|
    t.integer "line_item_id", null: false
    t.integer "action_id", null: false
    t.integer "quantity", default: 0
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["action_id"], name: "index_spree_line_item_actions_on_action_id"
    t.index ["line_item_id"], name: "index_spree_line_item_actions_on_line_item_id"
  end

  create_table "spree_line_item_monograms", force: :cascade do |t|
    t.bigint "line_item_id", null: false
    t.jsonb "customization"
    t.text "text", null: false
    t.decimal "price", null: false
    t.index ["line_item_id"], name: "index_spree_line_item_monograms_on_line_item_id"
  end

  create_table "spree_line_items", id: :serial, force: :cascade do |t|
    t.integer "variant_id"
    t.integer "order_id"
    t.integer "quantity", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.decimal "cost_price", precision: 10, scale: 2
    t.integer "tax_category_id"
    t.decimal "adjustment_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "additional_tax_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "promo_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "included_tax_total", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "vendor_id"
    t.bigint "mirakl_offer_id"
    t.bigint "mark_down_id"
    t.boolean "final_sale", default: false
    t.decimal "original_price", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "mark_down_our_liability"
    t.decimal "duty_fees", precision: 8, scale: 2
    t.string "discountable_type"
    t.bigint "discountable_id"
    t.index ["discountable_type", "discountable_id"], name: "index_spree_line_items_on_discountable_type_and_discountable_id"
    t.index ["mark_down_id"], name: "index_spree_line_items_on_mark_down_id"
    t.index ["mirakl_offer_id"], name: "index_spree_line_items_on_mirakl_offer_id"
    t.index ["order_id"], name: "index_spree_line_items_on_order_id"
    t.index ["variant_id"], name: "index_spree_line_items_on_variant_id"
    t.index ["vendor_id"], name: "index_spree_line_items_on_vendor_id"
  end

  create_table "spree_log_entries", id: :serial, force: :cascade do |t|
    t.string "source_type"
    t.string "source_id"
    t.text "details"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["source_id", "source_type"], name: "index_spree_log_entries_on_source_id_and_source_type"
  end

  create_table "spree_mark_down_sale_prices", force: :cascade do |t|
    t.integer "mark_down_id"
    t.integer "sale_price_id"
    t.index ["mark_down_id"], name: "index_spree_mark_down_sale_prices_on_mark_down_id"
    t.index ["sale_price_id"], name: "index_spree_mark_down_sale_prices_on_sale_price_id"
  end

  create_table "spree_mark_downs", force: :cascade do |t|
    t.string "title"
    t.decimal "amount"
    t.boolean "final_sale"
    t.decimal "our_liability"
    t.decimal "vendor_liability"
    t.boolean "active"
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_mark_downs_taxons", force: :cascade do |t|
    t.integer "mark_down_id"
    t.integer "taxon_id"
    t.boolean "exclude", default: false
    t.index ["mark_down_id"], name: "index_spree_mark_downs_taxons_on_mark_down_id"
    t.index ["taxon_id"], name: "index_spree_mark_downs_taxons_on_taxon_id"
  end

  create_table "spree_mark_downs_vendors", force: :cascade do |t|
    t.integer "mark_down_id"
    t.integer "vendor_id"
    t.boolean "exclude", default: false
    t.index ["mark_down_id"], name: "index_spree_mark_downs_vendors_on_mark_down_id"
    t.index ["vendor_id"], name: "index_spree_mark_downs_vendors_on_vendor_id"
  end

  create_table "spree_offer_settings", force: :cascade do |t|
    t.bigint "variant_id", null: false
    t.bigint "vendor_id", null: false
    t.boolean "monogrammable_only", default: false, null: false
    t.decimal "monogram_price", precision: 8, scale: 2
    t.decimal "monogram_cost_price", precision: 8, scale: 2
    t.integer "monogram_lead_time"
    t.integer "monogram_max_text_length", default: 20, null: false
    t.jsonb "monogram_customizations"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "monogrammable", default: false
    t.decimal "cost_price", precision: 8, scale: 2
    t.boolean "final_sale", default: false
    t.boolean "exclude_giftwrap"
    t.string "maisonette_sku", null: false
    t.string "vendor_sku"
    t.boolean "registry"
    t.decimal "permanent_sale_price", precision: 8, scale: 2
    t.jsonb "logistics_customizations", default: {}
    t.decimal "duty_fees", precision: 8, scale: 2
    t.index ["discarded_at"], name: "index_spree_offer_settings_on_discarded_at"
    t.index ["maisonette_sku"], name: "index_spree_offer_settings_on_maisonette_sku", unique: true
    t.index ["variant_id", "vendor_id"], name: "index_spree_offer_settings_on_variant_id_and_vendor_id", unique: true, where: "(discarded_at IS NULL)"
  end

  create_table "spree_option_type_prototypes", id: :serial, force: :cascade do |t|
    t.integer "prototype_id"
    t.integer "option_type_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
  end

  create_table "spree_option_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 100
    t.string "presentation", limit: 100
    t.integer "position", default: 0, null: false
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["name"], name: "index_spree_option_types_on_name", unique: true
    t.index ["position"], name: "index_spree_option_types_on_position"
  end

  create_table "spree_option_values", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.string "name"
    t.string "presentation"
    t.integer "option_type_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["name", "option_type_id"], name: "index_spree_option_values_on_name_and_option_type_id", unique: true
    t.index ["name"], name: "index_spree_option_values_on_name"
    t.index ["option_type_id"], name: "index_spree_option_values_on_option_type_id"
    t.index ["position"], name: "index_spree_option_values_on_position"
  end

  create_table "spree_option_values_variants", id: :serial, force: :cascade do |t|
    t.integer "variant_id"
    t.integer "option_value_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["variant_id", "option_value_id"], name: "index_option_values_variants_on_variant_id_and_option_value_id"
    t.index ["variant_id"], name: "index_spree_option_values_variants_on_variant_id"
  end

  create_table "spree_order_mutexes", id: :serial, force: :cascade do |t|
    t.integer "order_id", null: false
    t.datetime "created_at", precision: 6
    t.index ["order_id"], name: "index_spree_order_mutexes_on_order_id", unique: true
  end

  create_table "spree_orders", id: :serial, force: :cascade do |t|
    t.string "number", limit: 32
    t.decimal "item_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.string "state"
    t.decimal "adjustment_total", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "user_id"
    t.datetime "completed_at"
    t.integer "bill_address_id"
    t.integer "ship_address_id"
    t.decimal "payment_total", precision: 10, scale: 2, default: "0.0"
    t.string "shipment_state"
    t.string "payment_state"
    t.string "email"
    t.text "special_instructions"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "currency"
    t.string "last_ip_address"
    t.integer "created_by_id"
    t.decimal "shipment_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "additional_tax_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "promo_total", precision: 10, scale: 2, default: "0.0"
    t.string "channel", default: "spree"
    t.decimal "included_tax_total", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "item_count", default: 0
    t.integer "approver_id"
    t.datetime "approved_at"
    t.boolean "confirmation_delivered", default: false
    t.string "guest_token"
    t.datetime "canceled_at"
    t.integer "canceler_id"
    t.integer "store_id"
    t.string "approver_name"
    t.boolean "frontend_viewable", default: true, null: false
    t.boolean "migrated", default: false
    t.boolean "is_gift", default: false
    t.string "gift_email"
    t.text "gift_message"
    t.decimal "gift_card_total", precision: 10, scale: 2, default: "0.0"
    t.datetime "gift_confirmation_delivered_at"
    t.boolean "use_store_credits", default: false
    t.boolean "first_order", default: false
    t.uuid "maisonette_customer_id"
    t.jsonb "forter_connection_info", default: {}
    t.jsonb "browser_analytics", default: {}
    t.index ["approver_id"], name: "index_spree_orders_on_approver_id"
    t.index ["bill_address_id"], name: "index_spree_orders_on_bill_address_id"
    t.index ["completed_at"], name: "index_spree_orders_on_completed_at"
    t.index ["created_by_id"], name: "index_spree_orders_on_created_by_id"
    t.index ["email"], name: "index_spree_orders_on_email"
    t.index ["guest_token"], name: "index_spree_orders_on_guest_token"
    t.index ["maisonette_customer_id"], name: "index_spree_orders_on_maisonette_customer_id"
    t.index ["number"], name: "index_spree_orders_on_number"
    t.index ["ship_address_id"], name: "index_spree_orders_on_ship_address_id"
    t.index ["user_id", "created_by_id"], name: "index_spree_orders_on_user_id_and_created_by_id"
    t.index ["user_id"], name: "index_spree_orders_on_user_id"
    t.check_constraint :state_completed_at_check, "((completed_at IS NULL) OR ((state)::text <> ALL (ARRAY[('cart'::character varying)::text, ('address'::character varying)::text, ('delivery'::character varying)::text, ('payment'::character varying)::text, ('confirm'::character varying)::text])))"
  end

  create_table "spree_orders_promotions", id: :serial, force: :cascade do |t|
    t.integer "order_id"
    t.integer "promotion_id"
    t.integer "promotion_code_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["order_id", "promotion_id"], name: "index_spree_orders_promotions_on_order_id_and_promotion_id"
    t.index ["promotion_code_id"], name: "index_spree_orders_promotions_on_promotion_code_id"
  end

  create_table "spree_payment_capture_events", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0"
    t.integer "payment_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["payment_id"], name: "index_spree_payment_capture_events_on_payment_id"
  end

  create_table "spree_payment_methods", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.text "description"
    t.boolean "active", default: true
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.boolean "auto_capture"
    t.text "preferences"
    t.string "preference_source"
    t.integer "position", default: 0
    t.boolean "available_to_users", default: true
    t.boolean "available_to_admin", default: true
    t.index ["id", "type"], name: "index_spree_payment_methods_on_id_and_type"
  end

  create_table "spree_payments", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "order_id"
    t.string "source_type"
    t.integer "source_id"
    t.integer "payment_method_id"
    t.string "state"
    t.string "response_code"
    t.string "avs_response"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "number"
    t.string "cvv_response_code"
    t.string "cvv_response_message"
    t.index ["number"], name: "index_spree_payments_on_number", unique: true
    t.index ["order_id"], name: "index_spree_payments_on_order_id"
    t.index ["payment_method_id"], name: "index_spree_payments_on_payment_method_id"
    t.index ["source_id", "source_type"], name: "index_spree_payments_on_source_id_and_source_type"
  end

  create_table "spree_preferences", id: :serial, force: :cascade do |t|
    t.text "value"
    t.string "key"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["key"], name: "index_spree_preferences_on_key", unique: true
  end

  create_table "spree_prices", id: :serial, force: :cascade do |t|
    t.integer "variant_id", null: false
    t.decimal "amount", precision: 10, scale: 2
    t.string "currency"
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "country_iso", limit: 2
    t.integer "vendor_id"
    t.bigint "offer_settings_id"
    t.index ["country_iso"], name: "index_spree_prices_on_country_iso"
    t.index ["offer_settings_id"], name: "index_spree_prices_on_offer_settings_id"
    t.index ["variant_id", "currency"], name: "index_spree_prices_on_variant_id_and_currency"
    t.index ["vendor_id"], name: "index_spree_prices_on_vendor_id"
  end

  create_table "spree_product_option_types", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.integer "product_id"
    t.integer "option_type_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["option_type_id"], name: "index_spree_product_option_types_on_option_type_id"
    t.index ["position"], name: "index_spree_product_option_types_on_position"
    t.index ["product_id"], name: "index_spree_product_option_types_on_product_id"
  end

  create_table "spree_product_promotion_rules", id: :serial, force: :cascade do |t|
    t.integer "product_id"
    t.integer "promotion_rule_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["product_id"], name: "index_products_promotion_rules_on_product_id"
    t.index ["promotion_rule_id"], name: "index_products_promotion_rules_on_promotion_rule_id"
  end

  create_table "spree_product_properties", id: :serial, force: :cascade do |t|
    t.string "value"
    t.integer "product_id"
    t.integer "property_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.integer "position", default: 0
    t.bigint "maisonette_variant_group_attributes_id"
    t.index ["maisonette_variant_group_attributes_id"], name: "index_product_properties_variant_group_attributes"
    t.index ["position"], name: "index_spree_product_properties_on_position"
    t.index ["product_id"], name: "index_product_properties_on_product_id"
    t.index ["property_id"], name: "index_spree_product_properties_on_property_id"
  end

  create_table "spree_products", id: :serial, force: :cascade do |t|
    t.string "name", default: "", null: false
    t.text "description"
    t.datetime "available_on"
    t.datetime "deleted_at"
    t.string "slug"
    t.text "meta_description"
    t.string "meta_keywords"
    t.integer "tax_category_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.boolean "promotionable", default: true
    t.string "meta_title"
    t.datetime "available_until"
    t.boolean "gift_card", default: false
    t.boolean "concierge_only", default: false
    t.bigint "migrated_to_id"
    t.boolean "exclude_price_scraping", default: false
    t.datetime "discontinue_on"
    t.index ["available_on"], name: "index_spree_products_on_available_on"
    t.index ["deleted_at"], name: "index_spree_products_on_deleted_at"
    t.index ["migrated_to_id"], name: "index_spree_products_on_migrated_to_id"
    t.index ["name"], name: "index_spree_products_on_name"
    t.index ["slug"], name: "index_spree_products_on_slug", unique: true
  end

  create_table "spree_products_taxons", id: :serial, force: :cascade do |t|
    t.integer "product_id"
    t.integer "taxon_id"
    t.integer "position"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.bigint "maisonette_variant_group_attributes_id"
    t.index ["maisonette_variant_group_attributes_id"], name: "index_products_taxons_variant_group_attributes"
    t.index ["position"], name: "index_spree_products_taxons_on_position"
    t.index ["product_id", "taxon_id"], name: "index_spree_products_taxons_on_product_id_and_taxon_id"
    t.index ["product_id"], name: "index_spree_products_taxons_on_product_id"
    t.index ["taxon_id"], name: "index_spree_products_taxons_on_taxon_id"
  end

  create_table "spree_promotion_action_line_items", id: :serial, force: :cascade do |t|
    t.integer "promotion_action_id"
    t.integer "variant_id"
    t.integer "quantity", default: 1
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["promotion_action_id"], name: "index_spree_promotion_action_line_items_on_promotion_action_id"
    t.index ["variant_id"], name: "index_spree_promotion_action_line_items_on_variant_id"
  end

  create_table "spree_promotion_actions", id: :serial, force: :cascade do |t|
    t.integer "promotion_id"
    t.integer "position"
    t.string "type"
    t.datetime "deleted_at"
    t.text "preferences"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["deleted_at"], name: "index_spree_promotion_actions_on_deleted_at"
    t.index ["id", "type"], name: "index_spree_promotion_actions_on_id_and_type"
    t.index ["promotion_id"], name: "index_spree_promotion_actions_on_promotion_id"
  end

  create_table "spree_promotion_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "code"
    t.boolean "gift_card", default: false
    t.index ["name"], name: "index_spree_promotion_categories_on_name", unique: true
  end

  create_table "spree_promotion_code_batches", id: :serial, force: :cascade do |t|
    t.integer "promotion_id", null: false
    t.string "base_code", null: false
    t.integer "number_of_codes", null: false
    t.string "email"
    t.string "error"
    t.string "state", default: "pending"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "join_characters", default: "_", null: false
    t.index ["promotion_id"], name: "index_spree_promotion_code_batches_on_promotion_id"
  end

  create_table "spree_promotion_codes", id: :serial, force: :cascade do |t|
    t.integer "promotion_id", null: false
    t.string "value", null: false
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.integer "promotion_code_batch_id"
    t.datetime "expires_at"
    t.index ["promotion_code_batch_id"], name: "index_spree_promotion_codes_on_promotion_code_batch_id"
    t.index ["promotion_id"], name: "index_spree_promotion_codes_on_promotion_id"
    t.index ["value"], name: "index_spree_promotion_codes_on_value", unique: true
  end

  create_table "spree_promotion_rule_taxons", id: :serial, force: :cascade do |t|
    t.integer "taxon_id"
    t.integer "promotion_rule_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["promotion_rule_id"], name: "index_spree_promotion_rule_taxons_on_promotion_rule_id"
    t.index ["taxon_id"], name: "index_spree_promotion_rule_taxons_on_taxon_id"
  end

  create_table "spree_promotion_rules", id: :serial, force: :cascade do |t|
    t.integer "promotion_id"
    t.integer "product_group_id"
    t.string "type"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "code"
    t.text "preferences"
    t.index ["product_group_id"], name: "index_promotion_rules_on_product_group_id"
    t.index ["promotion_id"], name: "index_spree_promotion_rules_on_promotion_id"
  end

  create_table "spree_promotion_rules_stores", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "promotion_rule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["promotion_rule_id"], name: "index_spree_promotion_rules_stores_on_promotion_rule_id"
    t.index ["store_id"], name: "index_spree_promotion_rules_stores_on_store_id"
  end

  create_table "spree_promotion_rules_users", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "promotion_rule_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["promotion_rule_id"], name: "index_promotion_rules_users_on_promotion_rule_id"
    t.index ["user_id"], name: "index_promotion_rules_users_on_user_id"
  end

  create_table "spree_promotions", id: :serial, force: :cascade do |t|
    t.string "description"
    t.datetime "expires_at"
    t.datetime "starts_at"
    t.string "name"
    t.string "type"
    t.integer "usage_limit"
    t.string "match_policy", default: "all"
    t.boolean "advertise", default: false
    t.string "path"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.integer "promotion_category_id"
    t.integer "per_code_usage_limit"
    t.boolean "apply_automatically", default: false
    t.index ["advertise"], name: "index_spree_promotions_on_advertise"
    t.index ["apply_automatically"], name: "index_spree_promotions_on_apply_automatically"
    t.index ["expires_at"], name: "index_spree_promotions_on_expires_at"
    t.index ["id", "type"], name: "index_spree_promotions_on_id_and_type"
    t.index ["promotion_category_id"], name: "index_spree_promotions_on_promotion_category_id"
    t.index ["starts_at"], name: "index_spree_promotions_on_starts_at"
  end

  create_table "spree_properties", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "presentation", null: false
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["name"], name: "index_spree_properties_on_name", unique: true
  end

  create_table "spree_property_prototypes", id: :serial, force: :cascade do |t|
    t.integer "prototype_id"
    t.integer "property_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
  end

  create_table "spree_prototype_taxons", id: :serial, force: :cascade do |t|
    t.integer "taxon_id"
    t.integer "prototype_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["prototype_id"], name: "index_spree_prototype_taxons_on_prototype_id"
    t.index ["taxon_id"], name: "index_spree_prototype_taxons_on_taxon_id"
  end

  create_table "spree_prototypes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
  end

  create_table "spree_refund_reasons", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.boolean "mutable", default: true
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "code"
    t.string "mirakl_code"
  end

  create_table "spree_refunds", id: :serial, force: :cascade do |t|
    t.integer "payment_id"
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "transaction_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.integer "refund_reason_id"
    t.integer "reimbursement_id"
    t.index ["payment_id"], name: "index_spree_refunds_on_payment_id"
    t.index ["refund_reason_id"], name: "index_refunds_on_refund_reason_id"
    t.index ["reimbursement_id"], name: "index_spree_refunds_on_reimbursement_id"
  end

  create_table "spree_reimbursement_credits", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "reimbursement_id"
    t.integer "creditable_id"
    t.string "creditable_type"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
  end

  create_table "spree_reimbursement_gift_cards", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "reimbursement_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "spree_promotion_code_id"
    t.datetime "email_sent_at"
  end

  create_table "spree_reimbursement_types", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.boolean "mutable", default: true
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "type"
    t.index ["type"], name: "index_spree_reimbursement_types_on_type"
  end

  create_table "spree_reimbursements", id: :serial, force: :cascade do |t|
    t.string "number"
    t.string "reimbursement_status"
    t.integer "customer_return_id"
    t.integer "order_id"
    t.decimal "total", precision: 10, scale: 2
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["customer_return_id"], name: "index_spree_reimbursements_on_customer_return_id"
    t.index ["order_id"], name: "index_spree_reimbursements_on_order_id"
  end

  create_table "spree_return_authorizations", id: :serial, force: :cascade do |t|
    t.string "number"
    t.string "state"
    t.integer "order_id"
    t.text "memo"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.integer "stock_location_id"
    t.integer "return_reason_id"
    t.string "gift_recipient_email"
    t.string "tracking_url"
    t.boolean "waive_customer_return_fee", default: false, null: false
    t.index ["return_reason_id"], name: "index_return_authorizations_on_return_authorization_reason_id"
  end

  create_table "spree_return_items", id: :serial, force: :cascade do |t|
    t.integer "return_authorization_id"
    t.integer "inventory_unit_id"
    t.integer "exchange_variant_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.decimal "amount", precision: 12, scale: 4, default: "0.0", null: false
    t.decimal "included_tax_total", precision: 12, scale: 4, default: "0.0", null: false
    t.decimal "additional_tax_total", precision: 12, scale: 4, default: "0.0", null: false
    t.string "reception_status"
    t.string "acceptance_status"
    t.integer "customer_return_id"
    t.integer "reimbursement_id"
    t.integer "exchange_inventory_unit_id"
    t.text "acceptance_status_errors"
    t.integer "preferred_reimbursement_type_id"
    t.integer "override_reimbursement_type_id"
    t.boolean "resellable", default: true, null: false
    t.integer "return_reason_id"
    t.index ["customer_return_id"], name: "index_return_items_on_customer_return_id"
    t.index ["exchange_inventory_unit_id"], name: "index_spree_return_items_on_exchange_inventory_unit_id"
  end

  create_table "spree_return_reasons", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.boolean "mutable", default: true
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "mirakl_code"
  end

  create_table "spree_roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["name"], name: "index_spree_roles_on_name", unique: true
  end

  create_table "spree_roles_users", id: :serial, force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["role_id"], name: "index_spree_roles_users_on_role_id"
    t.index ["user_id", "role_id"], name: "index_spree_roles_users_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_spree_roles_users_on_user_id"
  end

  create_table "spree_sale_prices", id: :serial, force: :cascade do |t|
    t.integer "price_id"
    t.decimal "value", precision: 10, scale: 2, null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.boolean "enabled"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean "final_sale", default: false
    t.decimal "cost_price", precision: 8, scale: 2
    t.decimal "calculated_price", precision: 10, scale: 2
    t.boolean "permanent", default: false
    t.index ["deleted_at"], name: "index_spree_sale_prices_on_deleted_at"
    t.index ["price_id", "start_at", "end_at", "enabled"], name: "index_active_sale_prices_for_price"
    t.index ["price_id"], name: "index_sale_prices_for_price"
    t.index ["start_at", "end_at", "enabled"], name: "index_active_sale_prices_for_all_variants"
  end

  create_table "spree_shipments", id: :serial, force: :cascade do |t|
    t.string "tracking"
    t.string "number"
    t.decimal "cost", precision: 10, scale: 2, default: "0.0"
    t.datetime "shipped_at"
    t.integer "order_id"
    t.integer "deprecated_address_id"
    t.string "state"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.integer "stock_location_id"
    t.decimal "adjustment_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "additional_tax_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "promo_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "included_tax_total", precision: 10, scale: 2, default: "0.0", null: false
    t.string "easypost_error"
    t.string "shipping_carrier_code"
    t.string "override_tracking_url"
    t.string "delivery_estimation"
    t.index ["deprecated_address_id"], name: "index_spree_shipments_on_deprecated_address_id"
    t.index ["number"], name: "index_shipments_on_number"
    t.index ["order_id"], name: "index_spree_shipments_on_order_id"
    t.index ["stock_location_id"], name: "index_spree_shipments_on_stock_location_id"
  end

  create_table "spree_shipping_carriers", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "easypost_carrier_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_shipping_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
  end

  create_table "spree_shipping_method_carriers", force: :cascade do |t|
    t.integer "shipping_method_id", null: false
    t.integer "shipping_carrier_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shipping_carrier_id", "shipping_method_id"], name: "unique_spree_shipping_method_carriers", unique: true
    t.index ["shipping_method_id"], name: "index_spree_shipping_method_carriers_on_shipping_method_id"
  end

  create_table "spree_shipping_method_categories", id: :serial, force: :cascade do |t|
    t.integer "shipping_method_id", null: false
    t.integer "shipping_category_id", null: false
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["shipping_category_id", "shipping_method_id"], name: "unique_spree_shipping_method_categories", unique: true
    t.index ["shipping_method_id"], name: "index_spree_shipping_method_categories_on_shipping_method_id"
  end

  create_table "spree_shipping_method_promotion_rules", force: :cascade do |t|
    t.bigint "shipping_method_id"
    t.bigint "promotion_rule_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["promotion_rule_id"], name: "idx_shipping_method_promotion_rules_on_promotion_rule"
    t.index ["shipping_method_id"], name: "idx_shipping_method_promotion_rules_on_shipping_method"
  end

  create_table "spree_shipping_method_stock_locations", id: :serial, force: :cascade do |t|
    t.integer "shipping_method_id"
    t.integer "stock_location_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["shipping_method_id"], name: "shipping_method_id_spree_sm_sl"
    t.index ["stock_location_id"], name: "sstock_location_id_spree_sm_sl"
  end

  create_table "spree_shipping_method_zones", id: :serial, force: :cascade do |t|
    t.integer "shipping_method_id"
    t.integer "zone_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
  end

  create_table "spree_shipping_methods", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "tracking_url"
    t.string "admin_name"
    t.integer "tax_category_id"
    t.string "code"
    t.string "carrier"
    t.string "service_level"
    t.boolean "available_to_users", default: true
    t.string "flat_rate_class"
    t.decimal "expedited_flat_rate_adjustment", precision: 8, scale: 2, default: "0.0"
    t.string "mirakl_shipping_method_code"
    t.integer "delivery_time"
    t.integer "grace_period"
    t.integer "stock_location_filter", default: 0
    t.decimal "base_flat_rate_amount", precision: 8, scale: 2, default: "0.0"
    t.boolean "expedited", default: false, null: false
    t.index ["tax_category_id"], name: "index_spree_shipping_methods_on_tax_category_id"
  end

  create_table "spree_shipping_rate_taxes", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "tax_rate_id"
    t.integer "shipping_rate_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["shipping_rate_id"], name: "index_spree_shipping_rate_taxes_on_shipping_rate_id"
    t.index ["tax_rate_id"], name: "index_spree_shipping_rate_taxes_on_tax_rate_id"
  end

  create_table "spree_shipping_rates", id: :serial, force: :cascade do |t|
    t.integer "shipment_id"
    t.integer "shipping_method_id"
    t.boolean "selected", default: false
    t.decimal "cost", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.integer "tax_rate_id"
    t.index ["shipment_id", "shipping_method_id"], name: "spree_shipping_rates_join_index", unique: true
  end

  create_table "spree_state_changes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "previous_state"
    t.integer "stateful_id"
    t.integer "user_id"
    t.string "stateful_type"
    t.string "next_state"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["stateful_id", "stateful_type"], name: "index_spree_state_changes_on_stateful_id_and_stateful_type"
    t.index ["user_id"], name: "index_spree_state_changes_on_user_id"
  end

  create_table "spree_states", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "abbr"
    t.integer "country_id"
    t.datetime "updated_at", precision: 6
    t.datetime "created_at", precision: 6
    t.index ["country_id"], name: "index_spree_states_on_country_id"
  end

  create_table "spree_stock_items", id: :serial, force: :cascade do |t|
    t.integer "stock_location_id"
    t.integer "variant_id"
    t.integer "count_on_hand", default: 0, null: false
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.boolean "backorderable", default: false
    t.datetime "deleted_at"
    t.datetime "backorder_date"
    t.index ["deleted_at"], name: "index_spree_stock_items_on_deleted_at"
    t.index ["stock_location_id", "variant_id"], name: "stock_item_by_loc_and_var_id"
    t.index ["stock_location_id"], name: "index_spree_stock_items_on_stock_location_id"
    t.index ["variant_id", "stock_location_id"], name: "index_spree_stock_items_on_variant_id_and_stock_location_id", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "spree_stock_locations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.boolean "default", default: false, null: false
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.integer "state_id"
    t.string "state_name"
    t.integer "country_id"
    t.string "zipcode"
    t.string "phone"
    t.boolean "active", default: true
    t.boolean "backorderable_default", default: false
    t.boolean "propagate_all_variants", default: false
    t.string "admin_name"
    t.integer "position", default: 0
    t.boolean "restock_inventory", default: true, null: false
    t.boolean "fulfillable", default: true, null: false
    t.string "code"
    t.boolean "check_stock_on_transfer", default: true
    t.bigint "vendor_id"
    t.boolean "domestic_override", default: false, null: false
    t.string "easypost_address_id"
    t.index ["country_id"], name: "index_spree_stock_locations_on_country_id"
    t.index ["name"], name: "index_spree_stock_locations_on_name", unique: true
    t.index ["state_id"], name: "index_spree_stock_locations_on_state_id"
    t.index ["vendor_id"], name: "index_spree_stock_locations_on_vendor_id"
  end

  create_table "spree_stock_movements", id: :serial, force: :cascade do |t|
    t.integer "stock_item_id"
    t.integer "quantity", default: 0
    t.string "action"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "originator_type"
    t.integer "originator_id"
    t.index ["stock_item_id"], name: "index_spree_stock_movements_on_stock_item_id"
  end

  create_table "spree_store_credit_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
  end

  create_table "spree_store_credit_events", id: :serial, force: :cascade do |t|
    t.integer "store_credit_id", null: false
    t.string "action", null: false
    t.decimal "amount", precision: 8, scale: 2
    t.decimal "user_total_amount", precision: 8, scale: 2, default: "0.0", null: false
    t.string "authorization_code", null: false
    t.datetime "deleted_at"
    t.string "originator_type"
    t.integer "originator_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.decimal "amount_remaining", precision: 8, scale: 2
    t.integer "store_credit_reason_id"
    t.index ["deleted_at"], name: "index_spree_store_credit_events_on_deleted_at"
    t.index ["store_credit_id"], name: "index_spree_store_credit_events_on_store_credit_id"
  end

  create_table "spree_store_credit_reasons", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_store_credit_types", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "priority"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority"], name: "index_spree_store_credit_types_on_priority"
  end

  create_table "spree_store_credits", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "category_id"
    t.integer "created_by_id"
    t.decimal "amount", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "amount_used", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "amount_authorized", precision: 8, scale: 2, default: "0.0", null: false
    t.string "currency"
    t.text "memo"
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.integer "type_id"
    t.datetime "invalidated_at"
    t.index ["deleted_at"], name: "index_spree_store_credits_on_deleted_at"
    t.index ["type_id"], name: "index_spree_store_credits_on_type_id"
    t.index ["user_id"], name: "index_spree_store_credits_on_user_id"
  end

  create_table "spree_store_payment_methods", id: :serial, force: :cascade do |t|
    t.integer "store_id", null: false
    t.integer "payment_method_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["payment_method_id"], name: "index_spree_store_payment_methods_on_payment_method_id"
    t.index ["store_id"], name: "index_spree_store_payment_methods_on_store_id"
  end

  create_table "spree_store_shipping_methods", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "shipping_method_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["shipping_method_id"], name: "index_spree_store_shipping_methods_on_shipping_method_id"
    t.index ["store_id"], name: "index_spree_store_shipping_methods_on_store_id"
  end

  create_table "spree_stores", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.text "meta_description"
    t.text "meta_keywords"
    t.string "seo_title"
    t.string "mail_from_address"
    t.string "default_currency"
    t.string "code"
    t.boolean "default", default: false, null: false
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "cart_tax_country_iso"
    t.string "available_locales"
    t.string "mail_copy_address"
    t.string "default_season_code"
    t.text "enabled_shipping_service_levels"
    t.string "bcc_email"
    t.text "preferences"
    t.index ["code"], name: "index_spree_stores_on_code"
    t.index ["default"], name: "index_spree_stores_on_default"
  end

  create_table "spree_tax_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "is_default", default: false
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "tax_code"
  end

  create_table "spree_tax_rate_tax_categories", id: :serial, force: :cascade do |t|
    t.integer "tax_category_id", null: false
    t.integer "tax_rate_id", null: false
    t.index ["tax_category_id"], name: "index_spree_tax_rate_tax_categories_on_tax_category_id"
    t.index ["tax_rate_id"], name: "index_spree_tax_rate_tax_categories_on_tax_rate_id"
  end

  create_table "spree_tax_rates", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 8, scale: 5
    t.integer "zone_id"
    t.boolean "included_in_price", default: false
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "name"
    t.boolean "show_rate_in_label", default: true
    t.datetime "deleted_at"
    t.datetime "starts_at"
    t.datetime "expires_at"
    t.index ["deleted_at"], name: "index_spree_tax_rates_on_deleted_at"
    t.index ["zone_id"], name: "index_spree_tax_rates_on_zone_id"
  end

  create_table "spree_taxonomies", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.integer "position", default: 0
    t.index ["position"], name: "index_spree_taxonomies_on_position"
  end

  create_table "spree_taxons", id: :serial, force: :cascade do |t|
    t.integer "parent_id"
    t.integer "position", default: 0
    t.string "name", null: false
    t.string "permalink"
    t.integer "taxonomy_id"
    t.integer "lft"
    t.integer "rgt"
    t.string "icon_file_name"
    t.string "icon_content_type"
    t.integer "icon_file_size"
    t.datetime "icon_updated_at"
    t.text "description"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.string "meta_title"
    t.string "meta_description"
    t.string "meta_keywords"
    t.integer "depth"
    t.boolean "hidden", default: false
    t.boolean "highlight", default: false
    t.boolean "header_link", default: false
    t.string "url_override"
    t.boolean "add_flair", default: false
    t.boolean "track_insights", default: false
    t.string "google_product_category"
    t.text "short_description"
    t.string "view_all_url_override"
    t.jsonb "meta_data", default: {}
    t.index ["lft"], name: "index_spree_taxons_on_lft"
    t.index ["name"], name: "index_spree_taxons_on_name"
    t.index ["parent_id", "name", "taxonomy_id"], name: "index_spree_taxons_on_parent_id_and_name_and_taxonomy_id"
    t.index ["parent_id"], name: "index_taxons_on_parent_id"
    t.index ["permalink"], name: "index_spree_taxons_on_permalink", unique: true
    t.index ["position"], name: "index_spree_taxons_on_position"
    t.index ["rgt"], name: "index_spree_taxons_on_rgt"
    t.index ["taxonomy_id"], name: "index_taxons_on_taxonomy_id"
  end

  create_table "spree_unit_cancels", id: :serial, force: :cascade do |t|
    t.integer "inventory_unit_id", null: false
    t.string "reason"
    t.string "created_by"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.bigint "reimbursement_id"
    t.index ["inventory_unit_id"], name: "index_spree_unit_cancels_on_inventory_unit_id"
    t.index ["reimbursement_id"], name: "index_spree_unit_cancels_on_reimbursement_id"
  end

  create_table "spree_user_addresses", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "address_id", null: false
    t.boolean "default", default: false
    t.boolean "archived", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "default_billing", default: false
    t.index ["address_id"], name: "index_spree_user_addresses_on_address_id"
    t.index ["user_id", "address_id"], name: "index_spree_user_addresses_on_user_id_and_address_id", unique: true
    t.index ["user_id"], name: "index_spree_user_addresses_on_user_id"
  end

  create_table "spree_user_stock_locations", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "stock_location_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["user_id"], name: "index_spree_user_stock_locations_on_user_id"
  end

  create_table "spree_users", id: :serial, force: :cascade do |t|
    t.string "encrypted_password", limit: 128
    t.string "password_salt", limit: 128
    t.string "email"
    t.string "remember_token"
    t.string "persistence_token"
    t.string "reset_password_token"
    t.string "perishable_token"
    t.integer "sign_in_count", default: 0, null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_request_at"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "login"
    t.integer "ship_address_id"
    t.integer "bill_address_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "spree_api_key", limit: 48
    t.string "authentication_token"
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.datetime "deleted_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "first_name"
    t.string "last_name"
    t.boolean "receive_emails_agree", default: false
    t.string "exemption_number"
    t.string "vat_id"
    t.integer "avalara_entity_use_code_id"
    t.string "default_payment_method_token"
    t.index ["bill_address_id"], name: "index_spree_users_on_bill_address_id"
    t.index ["deleted_at"], name: "index_spree_users_on_deleted_at"
    t.index ["email"], name: "email_idx_unique", unique: true
    t.index ["reset_password_token"], name: "index_spree_users_on_reset_password_token_solidus_auth_devise", unique: true
    t.index ["ship_address_id"], name: "index_spree_users_on_ship_address_id"
    t.index ["spree_api_key"], name: "index_spree_users_on_spree_api_key"
  end

  create_table "spree_variant_property_rule_conditions", id: :serial, force: :cascade do |t|
    t.integer "option_value_id"
    t.integer "variant_property_rule_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["variant_property_rule_id", "option_value_id"], name: "index_spree_variant_prop_rule_conditions_on_rule_and_optval"
  end

  create_table "spree_variant_property_rule_values", id: :serial, force: :cascade do |t|
    t.text "value"
    t.integer "position", default: 0
    t.integer "property_id"
    t.integer "variant_property_rule_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["property_id"], name: "index_spree_variant_property_rule_values_on_property_id"
    t.index ["variant_property_rule_id"], name: "index_spree_variant_property_rule_values_on_rule"
  end

  create_table "spree_variant_property_rules", id: :serial, force: :cascade do |t|
    t.integer "product_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "apply_to_all", default: true, null: false
    t.index ["product_id"], name: "index_spree_variant_property_rules_on_product_id"
  end

  create_table "spree_variants", id: :serial, force: :cascade do |t|
    t.string "sku", default: "", null: false
    t.decimal "weight", precision: 8, scale: 2, default: "0.0"
    t.decimal "height", precision: 8, scale: 2
    t.decimal "width", precision: 8, scale: 2
    t.decimal "depth", precision: 8, scale: 2
    t.datetime "deleted_at"
    t.boolean "is_master", default: false
    t.integer "product_id"
    t.decimal "cost_price", precision: 10, scale: 2
    t.integer "position"
    t.string "cost_currency"
    t.boolean "track_inventory", default: true
    t.integer "tax_category_id"
    t.datetime "updated_at", precision: 6
    t.datetime "created_at", precision: 6
    t.integer "lead_time"
    t.bigint "shipping_category_id"
    t.datetime "available_until"
    t.string "marketplace_sku"
    t.jsonb "age_range"
    t.jsonb "clothing_sizes"
    t.jsonb "shoe_sizes"
    t.index ["position"], name: "index_spree_variants_on_position"
    t.index ["product_id"], name: "index_spree_variants_on_product_id"
    t.index ["shipping_category_id"], name: "index_spree_variants_on_shipping_category_id"
    t.index ["sku"], name: "index_spree_variants_on_sku", unique: true
    t.index ["tax_category_id"], name: "index_spree_variants_on_tax_category_id"
    t.index ["track_inventory"], name: "index_spree_variants_on_track_inventory"
  end

  create_table "spree_vendors", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "mirakl_shop_id"
    t.string "avalara_code"
    t.boolean "giftwrap_service"
    t.float "giftwrap_price"
    t.float "giftwrap_cost"
    t.index ["avalara_code"], name: "index_spree_vendors_on_avalara_code", unique: true
    t.index ["mirakl_shop_id"], name: "index_spree_vendors_on_mirakl_shop_id"
    t.index ["name"], name: "index_spree_vendors_on_name", unique: true
  end

  create_table "spree_wallet_payment_sources", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "payment_source_type", null: false
    t.integer "payment_source_id", null: false
    t.boolean "default", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id", "payment_source_id", "payment_source_type"], name: "index_spree_wallet_payment_sources_on_source_and_user", unique: true
    t.index ["user_id"], name: "index_spree_wallet_payment_sources_on_user_id"
  end

  create_table "spree_wished_products", force: :cascade do |t|
    t.bigint "wishlist_id"
    t.bigint "variant_id"
    t.integer "quantity"
    t.text "remark"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["variant_id"], name: "index_spree_wished_products_on_variant_id"
    t.index ["wishlist_id"], name: "index_spree_wished_products_on_wishlist_id"
  end

  create_table "spree_wishlists", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name"
    t.string "access_hash"
    t.boolean "is_public", default: false, null: false
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_spree_wishlists_on_user_id"
  end

  create_table "spree_zone_members", id: :serial, force: :cascade do |t|
    t.string "zoneable_type"
    t.integer "zoneable_id"
    t.integer "zone_id"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["zone_id"], name: "index_spree_zone_members_on_zone_id"
    t.index ["zoneable_id", "zoneable_type"], name: "index_spree_zone_members_on_zoneable_id_and_zoneable_type"
  end

  create_table "spree_zones", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "zone_members_count", default: 0
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
  end

  create_table "syndication_product_updates", force: :cascade do |t|
    t.datetime "started_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["started_at"], name: "index_syndication_product_updates_on_started_at", order: :desc
  end

  create_table "syndication_products", force: :cascade do |t|
    t.string "maisonette_product_id"
    t.string "maisonette_sku"
    t.string "manufacturer_id"
    t.string "size"
    t.string "option_type"
    t.string "product_name"
    t.string "vendor_sku_description"
    t.string "image"
    t.string "side_image"
    t.float "maisonette_retail"
    t.float "maisonette_sale"
    t.string "boutique"
    t.bigint "inventory"
    t.boolean "in_stock"
    t.boolean "discontinue"
    t.string "inventory_status"
    t.string "percent_off"
    t.string "product_url"
    t.string "brand"
    t.string "season"
    t.string "available_on"
    t.string "material"
    t.bigint "master_or_variant_id"
    t.boolean "has_more_colors"
    t.string "slug"
    t.boolean "is_product", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "upc"
    t.string "google_product_category"
    t.string "shipping_category"
    t.float "margin"
    t.string "marketplace_sku"
    t.float "estimated_shipping_cost"
    t.float "price_min"
    t.float "price_max"
    t.datetime "algolia_attributes_updated_at"
    t.integer "variants_count"
    t.integer "total_sales"
    t.string "pet_type"
    t.jsonb "age_range"
    t.jsonb "clothing_sizes"
    t.jsonb "shoe_sizes"
    t.jsonb "product_type"
    t.jsonb "gender"
    t.jsonb "color"
    t.jsonb "trends"
    t.jsonb "edits"
    t.jsonb "category"
    t.boolean "on_sale"
    t.boolean "best_seller"
    t.boolean "selling_fast"
    t.boolean "new"
    t.boolean "exclusive"
    t.boolean "most_wished"
    t.boolean "monogrammable"
    t.string "fixed_ref"
    t.string "main_category"
    t.string "asin"
    t.boolean "exclude_price_scraping", default: false
    t.integer "true_total_sales"
    t.boolean "size_broken"
    t.integer "lifetime_total_sales"
    t.string "holiday"
    t.string "exclusive_definition"
    t.float "cost_price"
    t.index ["manufacturer_id"], name: "index_syndication_products_on_manufacturer_id"
    t.index ["master_or_variant_id"], name: "index_syndication_products_on_master_or_variant_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "easypost_trackers", "easypost_orders"
  add_foreign_key "easypost_trackers", "spree_return_authorizations"
  add_foreign_key "maisonette_giftwraps", "spree_orders", column: "order_id"
  add_foreign_key "maisonette_giftwraps", "spree_shipments", column: "shipment_id"
  add_foreign_key "maisonette_giftwraps", "spree_stock_locations", column: "stock_location_id"
  add_foreign_key "maisonette_price_scraper_categories", "spree_taxons", column: "taxon_id"
  add_foreign_key "maisonette_sale_sku_configurations", "maisonette_sales", column: "sale_id"
  add_foreign_key "maisonette_sale_sku_configurations", "spree_offer_settings", column: "offer_settings_id"
  add_foreign_key "maisonette_sale_sku_configurations", "spree_sale_prices", column: "sale_price_id"
  add_foreign_key "maisonette_sale_sku_configurations", "spree_users", column: "created_by_id"
  add_foreign_key "maisonette_sale_sku_configurations", "spree_users", column: "updated_by_id"
  add_foreign_key "maisonette_sales", "spree_taxons", column: "taxon_id"
  add_foreign_key "maisonette_user_data_deletion_requests", "spree_users", column: "user_id"
  add_foreign_key "maisonette_variant_group_attributes", "spree_option_values", column: "option_value_id"
  add_foreign_key "maisonette_variant_group_attributes", "spree_products", column: "product_id"
  add_foreign_key "mirakl_offers", "spree_prices"
  add_foreign_key "mirakl_warehouses", "spree_addresses", column: "address_id"
  add_foreign_key "order_management_order_item_summaries", "order_management_sales_orders", column: "sales_order_id"
  add_foreign_key "order_management_order_summaries", "order_management_sales_orders", column: "sales_order_id"
  add_foreign_key "order_management_sales_orders", "spree_orders"
  add_foreign_key "salsify_import_rows", "salsify_imports"
  add_foreign_key "salsify_import_rows", "spree_products"
  add_foreign_key "solidus_afterpay_payment_sources", "spree_payment_methods", column: "payment_method_id"
  add_foreign_key "solidus_paypal_braintree_sources", "spree_payment_methods", column: "payment_method_id"
  add_foreign_key "spree_assets", "maisonette_variant_group_attributes", column: "maisonette_variant_group_attributes_id"
  add_foreign_key "spree_line_item_monograms", "spree_line_items", column: "line_item_id"
  add_foreign_key "spree_line_items", "spree_variants", column: "variant_id"
  add_foreign_key "spree_line_items", "spree_vendors", column: "vendor_id"
  add_foreign_key "spree_mark_down_sale_prices", "spree_mark_downs", column: "mark_down_id"
  add_foreign_key "spree_mark_down_sale_prices", "spree_sale_prices", column: "sale_price_id"
  add_foreign_key "spree_offer_settings", "spree_variants", column: "variant_id"
  add_foreign_key "spree_offer_settings", "spree_vendors", column: "vendor_id"
  add_foreign_key "spree_orders", "maisonette_customers"
  add_foreign_key "spree_product_properties", "maisonette_variant_group_attributes", column: "maisonette_variant_group_attributes_id"
  add_foreign_key "spree_products", "maisonette_variant_group_attributes", column: "migrated_to_id"
  add_foreign_key "spree_products_taxons", "maisonette_variant_group_attributes", column: "maisonette_variant_group_attributes_id"
  add_foreign_key "spree_promotion_code_batches", "spree_promotions", column: "promotion_id"
  add_foreign_key "spree_promotion_codes", "spree_promotion_code_batches", column: "promotion_code_batch_id"
  add_foreign_key "spree_shipping_method_promotion_rules", "spree_promotion_rules", column: "promotion_rule_id"
  add_foreign_key "spree_shipping_method_promotion_rules", "spree_shipping_methods", column: "shipping_method_id"
  add_foreign_key "spree_stock_locations", "spree_vendors", column: "vendor_id"
  add_foreign_key "spree_tax_rate_tax_categories", "spree_tax_categories", column: "tax_category_id"
  add_foreign_key "spree_tax_rate_tax_categories", "spree_tax_rates", column: "tax_rate_id"
  add_foreign_key "spree_variants", "spree_shipping_categories", column: "shipping_category_id"
  add_foreign_key "spree_vendors", "mirakl_shops"
  add_foreign_key "spree_wallet_payment_sources", "spree_users", column: "user_id"

  create_view "views_mirakl_orders", sql_definition: <<-SQL
      SELECT mirakl_orders.id,
      mirakl_orders.created_at,
      mirakl_orders.updated_at,
      mirakl_orders.logistic_order_id,
      mirakl_orders.state,
      mirakl_orders.incident,
      mirakl_orders.bulk_document_sent,
      spree_orders.number AS spree_orders_number,
      spree_stock_locations.name AS spree_stock_locations_name
     FROM ((((mirakl_orders
       JOIN mirakl_commercial_orders ON ((mirakl_orders.commercial_order_id = mirakl_commercial_orders.id)))
       JOIN spree_orders ON ((mirakl_commercial_orders.spree_order_id = spree_orders.id)))
       JOIN spree_shipments ON ((mirakl_orders.shipment_id = spree_shipments.id)))
       JOIN spree_stock_locations ON ((spree_shipments.stock_location_id = spree_stock_locations.id)));
  SQL
  create_view "views_easypost_trackers", sql_definition: <<-SQL
      SELECT easypost_trackers.id,
      easypost_trackers.created_at,
      easypost_trackers.updated_at,
      easypost_trackers.carrier,
      easypost_trackers.tracking_code,
      easypost_trackers.date_shipped,
      easypost_trackers.date_delivered,
      easypost_trackers.date_out_for_delivery,
      easypost_trackers.status,
      easypost_trackers.easypost_order_id
     FROM easypost_trackers;
  SQL
end
