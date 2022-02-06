# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::DeleteSaleSkuConfigurationsWorker do
  let(:sale) { create(:sale) }
  let(:user) { create(:user, email: 'merch@example.com') }
  let(:perform) { described_class.new.perform(sale.id, offer_settings_params) }
  let(:offer_settings) { create(:offer_settings) }
  let(:offer_settings_params) { { 'updated_by_id' => user.id } }

  describe '#perform' do
    context 'when offer settings params is empty' do
      let(:offer_settings_params) { {} }

      it 'raises empty offer settings params error' do
        expect { perform }.to(
          raise_error(Maisonette::CreateSaleSkuConfigurationsError).with_message('Empty offer settings params')
        )
      end
    end

    context 'when offer settings params is not empty' do
      before do
        allow(Maisonette::SaleConfigurationDeleteAllMailer).to receive(:with).and_return(mailer)
        create(:sale_sku_configuration, sale: sale, offer_settings: offer_settings)
        allow(Tempfile).to receive(:new).and_call_original
        allow(Tempfile).to receive(:new).with(['deleted_products', '.csv']).and_return(temp_file)
        allow(temp_file).to receive(:unlink)
        allow(Maisonette::BuildSaleCsvInteractor).to receive(:call).and_return(context)
      end

      after do
        allow(temp_file).to receive(:unlink).and_call_original
        temp_file.unlink
      end

      let(:mailer) { OpenStruct.new(delete_all_email: message_delivery) }
      let(:message_delivery) { instance_double(ActionMailer::Parameterized::MessageDelivery, deliver_now!: true) }
      let(:configurations_count) { sale.sale_sku_configurations.count }
      let(:temp_file) { Tempfile.new }
      let(:context) { instance_double('Context', success?: true, file: temp_file, csv_filename: file_name) }
      let(:collection) { { product_name: 'XYZ' } }
      let(:file_name) { 'deleted_products.csv' }

      it 'does not send an email and deletes all configurations if not available', skip_before: true do
        perform

        expect(Maisonette::SaleConfigurationDeleteAllMailer).not_to have_received(:with).with(
          recipient: user.email,
          sale_name: sale.name,
          configuration_count: configurations_count,
          file_path: temp_file.path
        )
        expect(sale.sale_sku_configurations.count).to eq(0)
      end

      it 'sends an email and deletes all configurations if available' do
        configurations_count
        perform

        expect(Maisonette::SaleConfigurationDeleteAllMailer).to have_received(:with).with(
          recipient: user.email,
          sale_name: sale.name,
          configuration_count: configurations_count,
          file_path: temp_file.path
        )
        expect(sale.sale_sku_configurations.count).to eq(0)
      end
    end
  end
end
