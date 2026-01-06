# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::SendDocumentsInteractor, mirakl: true do
  subject(:interactor) { described_class.new(args) }

  let(:documents_time) { Time.current }
  let(:args) do
    {
      total_items_quantity: 5,
      shop_id: shop.id,
      documents_time: documents_time,
      archive: 'Some zip data',
      order_ids: [1, 2, 3],
      batch: [1, 3]
    }
  end

  describe '#call' do
    let(:mailer) { OpenStruct.new(shop_documents_email: message_delivery) }
    let(:message_delivery) { instance_double(ActionMailer::Parameterized::MessageDelivery, deliver_now!: true) }
    let(:orders) { class_double Mirakl::Order, update_all: true }
    let(:orders_with_fixed_errors) { class_double Mirakl::Order, update_all: true }
    let(:logistic_order_ids) { %w[M123-A M123-B M124-A] }
    let(:logistic_order_ids_without_errors) { %w[M123-A M123-B] }
    let(:logistic_order_ids_with_fixed_errors) { %w[M124-A] }
    let(:shop) { build_stubbed(:mirakl_shop, email: 'some_email@maisonette.com') }
    let(:temp_file) { instance_double Tempfile, path: 'path/to/file' }

    before do
      allow(Mirakl::Order).to receive(:where).with(hash_including(bulk_document_error_sent: false)).and_return(orders)
      allow(Mirakl::Order).to(
        receive(:where).with(hash_including(bulk_document_error_sent: true)).and_return(orders_with_fixed_errors)
      )
      allow(orders).to receive(:pluck).with(:logistic_order_id).and_return(logistic_order_ids_without_errors)
      allow(orders_with_fixed_errors).to(
        receive(:pluck).with(:logistic_order_id).and_return(logistic_order_ids_with_fixed_errors)
      )

      allow(Mirakl::Shop).to receive(:find).and_return(shop)
      allow(Tempfile).to receive(:new).and_return(temp_file)
      allow(Mirakl::ShopDocumentsMailer).to receive(:with).and_return(mailer)
      allow(temp_file).to receive(:write).with('Some zip data')
      allow(temp_file).to receive_messages(rewind: nil, close: nil, unlink: nil)
      interactor.call
    end

    it 'loads the recipient shop' do
      expect(Mirakl::Shop).to have_received(:find).with(shop.id)
    end

    it 'stores the archive in a Tempfile' do
      expect(Tempfile).to have_received(:new).with(/shop#{shop.id}/)
    end

    it 'calls the mailer' do
      expect(Mirakl::ShopDocumentsMailer).to have_received(:with).with(
        recipient: shop.email,
        vendor_name: shop.name,
        orders: logistic_order_ids_without_errors,
        orders_with_fixed_errors: logistic_order_ids_with_fixed_errors,
        total_items_quantity: 5,
        documents_time: documents_time,
        batch_group: 1,
        batch_groups: 3,
        archive_path: temp_file.path
      )
    end
  end
end
