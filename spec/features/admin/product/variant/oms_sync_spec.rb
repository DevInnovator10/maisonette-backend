# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Product Variants Index Page', type: :feature do
  include Devise::Test::IntegrationHelpers

  let(:edit_page) { Admin::Products::Variants::EditPage.new }

  describe 'actions' do
    let(:product) { create :product, option_types: [option_type] }
    let(:option_type) { create :option_type, option_values: [option_value] }
    let(:option_value) { create :option_value }
    let(:variant) { create :variant, :in_stock, product: product, option_values: [option_value] }
    let(:user) { create :user }

    before do
      admin_role = Spree::Role.find_or_create_by(name: 'admin')
      Spree::RoleUser.create(user: user, role: admin_role)
      sign_in user
    end

    context 'when user do not have oms_backend role' do
      it 'displays an oms_sync tab' do
        edit_page.load(slug: product.slug, variant_id: variant.id)
        expect(edit_page).not_to have_oms_sync_tab
      end
    end

    context 'when user have oms_backend role' do
      before do
        oms_backend_role = Spree::Role.find_or_create_by(name: 'oms_backend')
        Spree::RoleUser.create(user: user, role: oms_backend_role)
      end

      it 'displays an oms_sync tab' do
        edit_page.load(slug: product.slug, variant_id: variant.id)
        expect(edit_page).to have_oms_sync_tab
      end
    end
  end
end
