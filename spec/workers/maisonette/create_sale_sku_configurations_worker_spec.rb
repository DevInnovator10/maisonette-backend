# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'sales sku configuration creation' do
  it 'creates a sku sale configuration for offer settings associated with the product' do
    perform
    sale_sku_configuration = sale.sale_sku_configurations.first

    expect(sale_sku_configuration.offer_settings).to eq(offer_settings)
  end

  it 'only creates a sku sale configuration for searched offer settings' do
    create_list(:offer_settings, 3)
    expect { perform }.to(change { sale.sale_sku_configurations.count }.by(1))
  end
end

RSpec.describe Maisonette::CreateSaleSkuConfigurationsWorker do
  let(:sale) { create(:sale) }
  let(:user) { create(:user, email: 'merch@example.com') }
  let(:perform) { described_class.new.perform(sale.id, offer_settings_params) }
  let(:offer_settings) { create(:offer_settings) }
  let(:offer_settings_params) { config_params.merge('updated_by_id' => user.id) }

  describe '#perform' do
    context 'when offer settings params is empty' do
      let(:offer_settings_params) { {} }

      it 'raises empty offer settings params error' do
        expect { perform }.to(
          raise_error(Maisonette::CreateSaleSkuConfigurationsError).with_message('Empty offer settings params')
        )
      end
    end

    context 'when offer settings is already in the sale' do
      let(:config_params) { { 'vendors_in' => [offer_settings.vendor_id] } }

      it 'does not create a new sale sku configuration' do
        create(:sale_sku_configuration, sale: sale, offer_settings: offer_settings)

        expect { perform }.not_to(change { sale.sale_sku_configurations.count })
      end

      it 'calls update on sale interactor' do
        sale_sku_configuration = create(:sale_sku_configuration, sale: sale, offer_settings: offer_settings)
        price = Spree::Price.find_by(vendor: offer_settings.vendor, variant: offer_settings.variant)
        offer_settings.update!(price: price)
        allow(::MaisonetteSale::UpdateOnSaleInteractor).to receive(:call!).and_call_original

        perform

        expect(::MaisonetteSale::UpdateOnSaleInteractor).to have_received(:call!).once.with(
          sale_sku_configuration: sale_sku_configuration,
          price: price

        )
      end
    end

    context 'when offer settings has a product name' do
      let(:config_params) { { 'product_name' => offer_settings.variant.product.name } }

      include_examples 'sales sku configuration creation'
    end

    context 'when offer settings has a vendor id' do
      let(:config_params) { { 'vendors_in' => [offer_settings.vendor_id] } }

      include_examples 'sales sku configuration creation'
    end

    context 'when offer settings has a sku' do
      let(:config_params) { { 'maisonette_sku_or_vendor_sku_or_variant_sku' => offer_settings.maisonette_sku } }

      include_examples 'sales sku configuration creation'
    end

    context 'when configuration params are received' do
      let(:start_date) { Time.zone.parse('2021-07-20 10:00') }
      let(:end_date) { Time.zone.parse('2021-07-30 10:00') }
      let(:config_params) do
        {
          'vendors_in' => [offer_settings.vendor_id],
          'percent_off' => '0.03',
          'maisonette_liability' => '15.0',
          'start_date' => start_date,
          'end_date' => end_date,
          'static_sale_price' => '20.5',
          'static_cost_price' => '15.3'
        }
      end

      it 'calls update on sale interactor' do
        price = Spree::Price.find_by(vendor: offer_settings.vendor, variant: offer_settings.variant)
        offer_settings.update!(price: price)
        allow(::MaisonetteSale::UpdateOnSaleInteractor).to receive(:call!).and_call_original

        perform
        sale_sku_configuration = sale.sale_sku_configurations.last

        expect(::MaisonetteSale::UpdateOnSaleInteractor).to have_received(:call!).once.with(
          sale_sku_configuration: sale_sku_configuration,
          price: price
        )
      end

      it 'creates a sku sale configuration with correct params' do
        perform
        sale_sku_configuration = sale.sale_sku_configurations.first

        expect(sale_sku_configuration).to have_attributes(
          offer_settings: offer_settings,
          percent_off: 0.03,
          maisonette_liability: 15.0,
          start_date: start_date,
          end_date: end_date,
          created_by: user,
          updated_by: user,
          static_sale_price: 20.5,
          static_cost_price: 15.3
        )
      end

      it 'updates a sku sale configuration with correct params' do
        user2 = create(:user)
        sale_sku_configuration = create(
          :sale_sku_configuration, sale: sale, offer_settings: offer_settings, percent_off: 0.05, created_by: user2
        )

        perform

        expect(sale_sku_configuration.reload).to have_attributes(
          offer_settings: offer_settings,
          percent_off: 0.03,
          maisonette_liability: 15.0,
          start_date: start_date,
          end_date: end_date,
          created_by: user2,
          updated_by: user,
          static_sale_price: 20.5,
          static_cost_price: 15.3
        )
      end

      context 'when attributes params are missing' do
        let(:config_params) { { 'vendors_in' => [offer_settings.vendor_id], 'percent_off' => 0.03 } }

        it 'clears a sku sale configuration attribute' do
          sale_sku_configuration = create(
            :sale_sku_configuration,
            sale: sale,
            offer_settings: offer_settings,
            maisonette_liability: 5.0,
            start_date: start_date,
            end_date: end_date
          )

          perform

          expect(sale_sku_configuration.reload).to have_attributes(
            offer_settings: offer_settings,
            percent_off: 0.03,
            maisonette_liability: nil,
            start_date: nil,
            end_date: nil,
            updated_by: user
          )
        end

        context 'when offer settings have no price' do
          it 'does not call update on sale interactor' do
            allow(::MaisonetteSale::UpdateOnSaleInteractor).to receive(:call!).and_call_original

            perform

            expect(::MaisonetteSale::UpdateOnSaleInteractor).not_to have_received(:call!)
          end
        end
      end
    end

    context 'when a file path is received' do
      let(:offer_settings_params) { { 'file_path' => 'maisonette_sale/file_path', 'updated_by_id' => user.id } }

      let(:mailer) { OpenStruct.new(bulk_update_email: message_delivery) }
      let(:message_delivery) { instance_double(ActionMailer::Parameterized::MessageDelivery, deliver_now!: true) }

      let(:successful_temp_file) { Tempfile.new }
      let(:unsuccessful_temp_file) { Tempfile.new }

      let(:successful_csv_content) do
        CSV.generate(col_sep: ',') do |csv|
          csv << Maisonette::BulkEditSaleCsvInteractor::HEADERS
          csv << ['Product Name', nil, 'Maisonette SKU', nil, '10', '50', nil, nil, nil, nil, nil, nil]
        end
      end

      let(:unsuccessful_csv_content) do
        CSV.generate(col_sep: ',') do |csv|
          csv << (Maisonette::BulkEditSaleCsvInteractor::HEADERS + ['Errors'])
          csv << ['Product Name', nil, 'Maisonette SKU', nil, '10', '50', nil, nil, nil, nil, nil, nil, 'Error']
        end
      end

      let(:row) do
        {
          'Product Name' => 'Product Name',
          'Vendor Name' => nil,
          'Maisonette SKU' => 'Maisonette SKU',
          'Vendor SKU' => nil,
          'Percent Off' => '10',
          'Maisonette Liability' => '50',
          'Final Sale' => nil,
          'Start Date' => nil,
          'End Date' => nil,
          'Sale Price' => nil,
          'Cost Price' => nil,
          'Remove from Sale' => nil
        }
      end

      let(:successful_rows) { { row => [] } }
      let(:unsuccessful_rows) { { row => ['Error'] } }

      before do
        # rubocop:disable RSpec/VerifiedDoubles
        s3_object = double(get: double(body: StringIO.new('content'), content_type: 'csv'))
        # rubocop:enable RSpec/VerifiedDoubles
        allow(S3).to receive(:object).with('maisonette_sale/file_path').and_return(s3_object)
        allow(::Maisonette::BulkEditSaleCsvInteractor).to receive(:call!).and_return(
          instance_double('Context', failure?: false, successful: successful_rows, unsuccessful: unsuccessful_rows)
        )
        allow(S3).to receive(:delete)
        allow(Maisonette::SaleBulkUpdateMailer).to receive(:with).and_return(mailer)
        allow(Tempfile).to receive(:new).and_call_original
        allow(Tempfile).to receive(:new).with(['successful_csv', '.csv']).and_return(successful_temp_file)
        allow(Tempfile).to receive(:new).with(['unsuccessful_csv', '.csv']).and_return(unsuccessful_temp_file)
        allow(successful_temp_file).to receive(:unlink)
        allow(unsuccessful_temp_file).to receive(:unlink)
      end

      after do
        allow(successful_temp_file).to receive(:unlink).and_call_original
        allow(unsuccessful_temp_file).to receive(:unlink).and_call_original
        successful_temp_file.unlink
        unsuccessful_temp_file.unlink
      end

      it 'calls bulk edit sale csv interactor' do
        perform

        expect(::Maisonette::BulkEditSaleCsvInteractor).to have_received(:call!).once.with(
          sale_id: sale.id,
          file_content: 'content',
          file_type: 'csv',
          updated_by_id: user.id
        )
      end

      it 'deletes proccessed file' do
        perform

        expect(S3).to have_received(:delete).with('maisonette_sale/file_path')
      end

      context 'when there are errors and successes' do
        it 'calls the mailer' do
          perform

          expect(Maisonette::SaleBulkUpdateMailer).to have_received(:with).with(
            recipient: user.email,
            sale_name: sale.name,
            successful_file_path: successful_temp_file.path,
            unsuccessful_file_path: unsuccessful_temp_file.path,
            successful_count: successful_rows.count,
            unsuccessful_count: unsuccessful_rows.count
          )
        end

        it 'creates the successful CSV' do
          perform

          expect(File.read(successful_temp_file.path)).to eq(successful_csv_content)
        end

        it 'creates the unsuccessful CSV' do
          perform

          expect(File.read(unsuccessful_temp_file.path)).to eq(unsuccessful_csv_content)
        end
      end

      context 'when there are no errors' do
        let(:unsuccessful_rows) { {} }

        it 'calls the mailer' do
          perform

          expect(Maisonette::SaleBulkUpdateMailer).to have_received(:with).with(
            recipient: user.email,
            sale_name: sale.name,
            successful_file_path: successful_temp_file.path,
            unsuccessful_file_path: nil,
            successful_count: successful_rows.count,
            unsuccessful_count: unsuccessful_rows.count
          )
        end

        it 'creates the successful CSV' do
          perform

          expect(File.read(successful_temp_file.path)).to eq(successful_csv_content)
        end

        it "doesn't create the unsuccessful CSV" do
          perform

          expect(Tempfile).not_to have_received(:new).with(['unsuccessful_csv', '.csv'])
        end
      end

      context 'when there are only errors' do
        let(:successful_rows) { {} }

        it 'calls the mailer' do
          perform

          expect(Maisonette::SaleBulkUpdateMailer).to have_received(:with).with(
            recipient: user.email,
            sale_name: sale.name,
            successful_file_path: nil,
            unsuccessful_file_path: unsuccessful_temp_file.path,
            successful_count: successful_rows.count,
            unsuccessful_count: unsuccessful_rows.count
          )
        end

        it "doesn't create the successful CSV" do
          perform

          expect(Tempfile).not_to have_received(:new).with(['successful_csv', '.csv'])
        end

        it 'creates the unsuccessful CSV' do
          perform

          expect(File.read(unsuccessful_temp_file.path)).to eq(unsuccessful_csv_content)
        end
      end
    end
  end
end
