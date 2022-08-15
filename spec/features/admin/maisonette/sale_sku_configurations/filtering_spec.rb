# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sale Sku Configurations Page', :js, type: :feature do
  include Devise::Test::IntegrationHelpers

  stub_authorization!

  let(:index_page) { Admin::Maisonette::SaleSkuConfigurations::IndexPage.new }
  let(:feature_enabled) { true }

  before do
    allow(Flipper).to receive(:enabled?).with(:maisonette_sale, anything).and_return(feature_enabled)
  end

  context 'when filtering the sale sku configuration index page' do
    context 'when there are multiple sale sku configurations' do
      let(:sale) do
        create :sale, start_date: Time.zone.yesterday, end_date: nil, permanent: true, percent_off: 0.3
      end

      let(:product1) { create(:product_in_stock) }
      let(:stock_location1) { product1.master.stock_items.first.stock_location }
      let(:vendor1) { create(:vendor, name: 'Vendor1', stock_location: stock_location1) }
      let(:created_by_user1) { create(:user, email: 'c_user1@example.com') }
      let(:updated_by_user1) { create(:user, email: 'u_user1@example.com') }
      let(:offer_settings1) do
        create :offer_settings, variant: product1.master, vendor: vendor1, maisonette_sku: 'ms-001'
      end

      let!(:sale_sku_configuration_active) do
        create :sale_sku_configuration,
               sale: sale, end_date: Time.zone.yesterday + 6.days, percent_off: 0.4,
               offer_settings: offer_settings1, created_by: created_by_user1, updated_by: updated_by_user1
      end

      let(:product2) { create(:product) }
      let(:vendor2) { create(:vendor, name: 'Vendor2') }
      let(:created_by_user2) { create(:user, email: 'c_user2@example.com') }
      let(:updated_by_user2) { create(:user, email: 'u_user2@example.com') }
      let(:offer_settings2) do
        create :offer_settings, variant: product2.master, vendor: vendor2, vendor_sku: 'vs-002'
      end

      let!(:sale_sku_configuration_inactive) do
        create :sale_sku_configuration,
               sale: sale, start_date: Time.zone.yesterday + 1.week,
               offer_settings: offer_settings2, created_by: created_by_user2, updated_by: updated_by_user2
      end

      before { index_page.load(sale_id: sale.id) }

      it 'can filter sale_sku_configurations by percent_off' do
        index_page.filter_by_percent_off('40', search: true)

        expect(page).to have_content "#{sale_sku_configuration_active.config_for(:percent_off) * 100}%"
        expect(page).not_to have_content "#{sale_sku_configuration_inactive.config_for(:percent_off) * 100}%"

        index_page.filter_by_percent_off('30', search: true)

        expect(page).to have_content "#{sale_sku_configuration_inactive.config_for(:percent_off) * 100}%"
        expect(page).not_to have_content "#{sale_sku_configuration_active.config_for(:percent_off) * 100}%"

        expect(index_page).to have_export_button
      end

      it 'can filter sale_sku_configurations by in_stock' do
        index_page.filter_by_in_stock(true, search: true)

        expect(page).to have_content "#{sale_sku_configuration_active.config_for(:percent_off) * 100}%"
        expect(page).not_to have_content "#{sale_sku_configuration_inactive.config_for(:percent_off) * 100}%"

        index_page.filter_by_in_stock(false, search: true)

        expect(page).to have_content "#{sale_sku_configuration_active.config_for(:percent_off) * 100}%"
        expect(page).to have_content "#{sale_sku_configuration_inactive.config_for(:percent_off) * 100}%"
      end

      it 'can filter sale_sku_configurations by active on date' do
        index_page.filter_by_date(Time.zone.today, search: true)

        expect(page).to have_content "#{sale_sku_configuration_active.config_for(:percent_off) * 100}%"
        expect(page).not_to have_content "#{sale_sku_configuration_inactive.config_for(:percent_off) * 100}%"

        index_page.filter_by_date(Time.zone.today + 1.week, search: true)

        expect(page).to have_content "#{sale_sku_configuration_inactive.config_for(:percent_off) * 100}%"
        expect(page).not_to have_content "#{sale_sku_configuration_active.config_for(:percent_off) * 100}%"
      end

      it 'can filter sale_sku_configurations by included taxons' do
        taxon1 = create(:taxon, name: 'Baby Clothes')
        product1.taxons << taxon1

        taxon2 = create(:taxon, name: 'Gear')
        product2.taxons << taxon2

        index_page.filter_by_taxon 'Baby Clothes', search: true

        expect(page).to have_content "#{sale_sku_configuration_active.config_for(:percent_off) * 100}%"
        expect(page).not_to have_content "#{sale_sku_configuration_inactive.config_for(:percent_off) * 100}%"

        index_page.remove_taxon 'Baby Clothes'
        index_page.filter_by_taxon 'Gear', search: true

        expect(page).to have_content "#{sale_sku_configuration_inactive.config_for(:percent_off) * 100}%"
        expect(page).not_to have_content "#{sale_sku_configuration_active.config_for(:percent_off) * 100}%"
      end

      it 'can filter sale_sku_configurations by included vendors' do
        index_page.filter_by_vendor 'Vendor1', search: true

        expect(page).to have_content "#{sale_sku_configuration_active.config_for(:percent_off) * 100}%"
        expect(page).not_to have_content "#{sale_sku_configuration_inactive.config_for(:percent_off) * 100}%"

        index_page.remove_vendor 'Vendor1'
        index_page.filter_by_vendor 'Vendor2', search: true

        expect(page).to have_content "#{sale_sku_configuration_inactive.config_for(:percent_off) * 100}%"
        expect(page).not_to have_content "#{sale_sku_configuration_active.config_for(:percent_off) * 100}%"
      end

      it 'can filter sale_sku_configurations by created by' do
        index_page.filter_by_created_by 'c_user1@example.com', search: true

        expect(page).to have_content 'c_user1@example.com'
        expect(page).not_to have_content 'c_user2@example.com'

        index_page.remove_created_by 'c_user1@example.com'
        index_page.filter_by_created_by 'c_user2@example.com', search: true

        expect(page).to have_content 'c_user2@example.com'
        expect(page).not_to have_content 'c_user1@example.com'
      end

      it 'can filter sale_sku_configurations by updated by' do
        index_page.filter_by_updated_by 'u_user1@example.com', search: true

        expect(page).to have_content 'u_user1@example.com'
        expect(page).not_to have_content 'u_user2@example.com'

        index_page.remove_updated_by 'u_user1@example.com'
        index_page.filter_by_updated_by 'u_user2@example.com', search: true

        expect(page).to have_content 'u_user2@example.com'
        expect(page).not_to have_content 'u_user1@example.com'
      end

      context 'when exporting the search results' do
        it 'displays a scheduled process message to user' do
          index_page.export_button.click
          scheduled_msg = "Your export is currently processing, you'll receive an email upon completion"
          expect(page).to have_content(scheduled_msg)
        end

        it 'schedules an export sale sku configurations job' do
          user = create(:user, email: 'merch@example.com')
          sign_in user

          allow(::Maisonette::ExportSaleSkuConfigurationsWorker).to receive_messages(perform_async: true)

          index_page.filter_by_percent_off('40', search: true)
          index_page.export_button.click

          search_query = { 'config_for_final_sale_eq' => '0', 'in_stock' => '0',
                           'config_for_percent_off_eq' => 0.4 }
          expect(::Maisonette::ExportSaleSkuConfigurationsWorker).to(
            have_received(:perform_async).with(sale.id.to_s, search_query, user.id)
          )
        end
      end

      context 'when filtering with a file' do
        let(:product3) { create(:product, name: 'Product, 3') }
        let(:vendor3) { create(:vendor, name: 'Vendor3') }
        let(:offer_settings3) do
          create :offer_settings, variant: product3.master, vendor: vendor3, maisonette_sku: 'ms-003'
        end

        before { offer_settings3 }

        context 'when the file is a CSV' do
          it 'can filter sale_sku_configurations' do
            index_page.select_file 'search.csv', search: true

            tds = index_page.all('table#listing_maisonette_sale_sku_configurations tr td:nth-child(5)').map do |td|
              td['innerHTML'].strip
            end

            expect(tds).to contain_exactly(
              "#{sale_sku_configuration_active.config_for(:percent_off) * 100}%",
              "#{sale_sku_configuration_inactive.config_for(:percent_off) * 100}%",
              '-'
            )

            expect(index_page).not_to have_export_button
          end
        end

        context 'when the file is a XLSX' do
          it 'can filter sale_sku_configurations' do
            index_page.select_file 'search.xlsx', search: true

            tds = index_page.all('table#listing_maisonette_sale_sku_configurations tr td:nth-child(5)').map do |td|
              td['innerHTML'].strip
            end

            expect(tds).to contain_exactly(
              "#{sale_sku_configuration_active.config_for(:percent_off) * 100}%",
              "#{sale_sku_configuration_inactive.config_for(:percent_off) * 100}%",
              '-'
            )
          end
        end

        context 'when the parse sale csv fails' do
          it 'returns the context error' do
            # rubocop:disable RSpec/VerifiedDoubles
            context = double(Interactor::Context, success?: false, message: 'parse error')
            # rubocop:enable RSpec/VerifiedDoubles
            allow(::Maisonette::ParseSaleCsvInteractor).to receive(:call).and_return(context)
            index_page.select_file 'search.xlsx', search: true

            expect(index_page).to have_content('We got an error while processing your file: parse error')
          end

          it 'captures general errors' do
            allow(Sentry).to receive(:capture_exception_with_message)
            allow(::Maisonette::ParseSaleCsvInteractor).to receive(:call).and_raise(StandardError.new('fail'))
            index_page.select_file 'search.xlsx', search: true

            expect(Sentry).to have_received(:capture_exception_with_message).with(StandardError, message: 'fail')
            expect(index_page).to have_content('We got an error while processing your file: fail')
          end
        end
      end
    end
  end
end
