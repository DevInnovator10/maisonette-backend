# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Kustomer::ReturnItemPresenter do
  describe '#kustomer_payload' do
    subject { described_class.new(return_item).kustomer_payload }

    let(:return_item) { create(:return_item) }

    it do
      is_expected.to match hash_including(
        'returnAuthorizationNumber' => return_item.return_authorization.number,
        'maisonetteSku' => nil,
        'sku' => return_item.variant.sku,
        'size' => return_item.variant.option_values.first.presentation,
        'vendorName' => return_item.inventory_unit.shipment.vendor.name,
        'receptionStatus' => return_item.reception_status,
        'variantDeletedAt' => nil
      )
    end

    context 'when offer_settings is present' do
      let(:line_item) { return_item.inventory_unit.line_item }

      before do
        line_item.vendor.save
        create(:price, variant: line_item.variant, vendor: line_item.vendor)
        create(:offer_settings, variant: line_item.variant, vendor: line_item.vendor)
        line_item.save
        line_item.reload
      end

      it 'returns the maisonetteSku' do
        is_expected.to match hash_including(
          'maisonetteSku' => line_item.offer_settings.maisonette_sku
        )
      end
    end

    context 'when variant has no option values' do
      it 'returns nil for size' do
        return_item.variant.update!(option_values: [])

        is_expected.to match hash_including(
          'size' => nil
        )
      end
    end

    context 'when variant is deleted' do
      it 'returns variant deleted at' do
        return_item.variant.destroy!

        is_expected.to match hash_including(
          'variantDeletedAt' => return_item.variant.deleted_at
        )
      end
    end
  end
end
