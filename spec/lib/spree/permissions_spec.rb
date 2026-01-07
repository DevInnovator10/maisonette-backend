# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe 'Permissions' do # rubocop:disable RSpec/DescribeClass
  describe 'cancan permissions' do
    subject(:permission_sets) { Spree::Config.roles.roles[role].permission_sets.to_a }

    describe 'default' do
      let(:role) { 'default' }
      let(:default_permissions) do
        [Spree::PermissionSets::DefaultCustomer,
         Spree::PermissionSets::WishlistManagement,
         Spree::PermissionSets::MinisManagement,
         Spree::PermissionSets::GiftwrapsManagement,
         Spree::PermissionSets::SitemapManagement,
         Spree::PermissionSets::SubscribersManagement,
         Spree::PermissionSets::EasyPostWebhookManagement]
      end

      it { is_expected.to match_array(default_permissions) }
    end

    describe 'merch' do
      let(:role) { 'merch' }
      let(:merch_permissions) do
        [Spree::PermissionSets::OrderDisplay,
         Spree::PermissionSets::ProductDisplay,
         Spree::PermissionSets::VariantDisplay,
         Spree::PermissionSets::StockDisplay,
         Spree::PermissionSets::UserDisplay,
         Spree::PermissionSets::MarketplaceDisplay,
         Spree::PermissionSets::PromotionManagement,
         Spree::PermissionSets::MarkDownManagement,
         Spree::PermissionSets::MigrationLogDisplay,
         Spree::PermissionSets::SalsifyDisplay,
         Spree::PermissionSets::MaisonetteSaleManagement]
      end

      it { is_expected.to match_array(merch_permissions) }
    end

    describe 'admin_merch' do
      let(:role) { 'merch_admin' }
      let(:merch_permissions) do
        [Spree::PermissionSets::OrderDisplay,
         Spree::PermissionSets::ProductDisplay,
         Spree::PermissionSets::VariantDisplay,
         Spree::PermissionSets::StockDisplay,
         Spree::PermissionSets::UserDisplay,
         Spree::PermissionSets::MarketplaceDisplay,
         Spree::PermissionSets::PromotionManagement,
         Spree::PermissionSets::MarkDownManagement,
         Spree::PermissionSets::MigrationLogDisplay,
         Spree::PermissionSets::SalsifyDisplay,
         Spree::PermissionSets::UserRoleManagement,
         Spree::PermissionSets::UserManagement,
         Spree::PermissionSets::TaxonomyManagement,
         Spree::PermissionSets::MaisonetteSaleManagement,
         Spree::PermissionSets::MiraklDeleteProducts,
         Spree::PermissionSets::PriceScraperManagement]
      end

      it { is_expected.to match_array(merch_permissions) }
    end

    describe 'customer_care' do
      let(:role) { 'customer_care' }
      let(:customer_care_permissions) do
        [Spree::PermissionSets::OrderManagement,
         Spree::PermissionSets::ProductDisplay,
         Spree::PermissionSets::VariantDisplay,
         Spree::PermissionSets::MarketplaceDisplay,
         Spree::PermissionSets::PromotionManagement,
         Spree::PermissionSets::GiftCardManagement,
         Spree::PermissionSets::StockDisplay,
         Spree::PermissionSets::UserManagement,
         Spree::PermissionSets::MiraklDisplay,
         Spree::PermissionSets::NarvarDisplay,
         Spree::PermissionSets::MarkDownDisplay,
         Spree::PermissionSets::MigrationLogDisplay,
         Spree::PermissionSets::EasypostDisplay,
         Spree::PermissionSets::BraintreeDisputeDisplay]

      end

      it { is_expected.to match_array(customer_care_permissions) }
    end

    describe 'customer_care_admin' do
      let(:role) { 'customer_care_admin' }
      let(:customer_care_permissions) do
        [Spree::PermissionSets::OrderManagement,
         Spree::PermissionSets::ProductDisplay,
         Spree::PermissionSets::VariantDisplay,
         Spree::PermissionSets::MarketplaceDisplay,
         Spree::PermissionSets::PromotionManagement,
         Spree::PermissionSets::GiftCardManagement,
         Spree::PermissionSets::StockDisplay,
         Spree::PermissionSets::UserManagement,
         Spree::PermissionSets::MiraklDisplay,
         Spree::PermissionSets::NarvarDisplay,
         Spree::PermissionSets::MarkDownDisplay,
         Spree::PermissionSets::MigrationLogDisplay,
         Spree::PermissionSets::EasypostDisplay,
         Spree::PermissionSets::BraintreeDisputeDisplay,
         Spree::PermissionSets::UserRoleManagement]
      end

      it { is_expected.to match_array(customer_care_permissions) }
    end
  end
end
