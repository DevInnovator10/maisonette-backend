# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Admin::MiraklStockLocationsHelper, mirakl: true do
  let(:described_class) { FakeStockLocationsController }

  describe '#invoice_date_range', freeze_time: Time.zone.local(2017, 9, 15) do
    subject(:invoice_date_range) { described_class.new.invoice_date_range }

    it 'returns the invoice date range covering last month' do
      expect(invoice_date_range).to eq '2017-Aug-01 - 2017-Aug-31'
    end
  end

  describe '#resubmit_fees_invoice_are_you_sure' do
    let(:fake_controller) { described_class.new }

    let(:stock_location) { instance_double Spree::StockLocation, id: 123, mirakl_shop: mirakl_shop }
    let(:mirakl_shop) { instance_double Mirakl::Shop }
    let(:fee_mirakl_invoices) { class_double Mirakl::Invoice }
    let(:shop_invoice_collection) { class_double Mirakl::Invoice }

    before do
      allow(fake_controller).to receive_messages(params: { id: stock_location.id })
      fake_controller.stock_location = stock_location
      allow(Mirakl::Invoice).to receive_messages(INVOICE: fee_mirakl_invoices)
      allow(fee_mirakl_invoices).to(
        receive(:where).with(issued: false, mirakl_shop: mirakl_shop).and_return(shop_invoice_collection)
      )
      allow(shop_invoice_collection).to receive(:pluck).with(:invoice_id).and_return([1, 2, 3])
    end

    it 'returns create_fee_invoice_are_you_sure message' do
      expect(fake_controller.resubmit_fees_invoice_are_you_sure).to(
        eq <<~STRING.chomp
          Warning... This will recreate the fee's invoice in Mirakl and will overwrite any manual adjustments.
          ID's shown below:
          1

          2
          3
      STRING
      )
    end
  end

  describe '#resubmit_credits_invoice_are_you_sure' do
    let(:fake_controller) { described_class.new }

    let(:stock_location) { instance_double Spree::StockLocation, id: 123, mirakl_shop: mirakl_shop }
    let(:mirakl_shop) { instance_double Mirakl::Shop }
    let(:credit_mirakl_invoices) { class_double Mirakl::Invoice }
    let(:shop_invoice_collection) { class_double Mirakl::Invoice }

    before do
      allow(fake_controller).to receive_messages(params: { id: stock_location.id })
      fake_controller.stock_location = stock_location
      allow(Mirakl::Invoice).to receive_messages(CREDIT: credit_mirakl_invoices)
      allow(credit_mirakl_invoices).to(
        receive(:where).with(issued: false, mirakl_shop: mirakl_shop).and_return(shop_invoice_collection)
      )
      allow(shop_invoice_collection).to receive(:pluck).with(:invoice_id).and_return([9, 8, 7])
    end

    it 'returns create_credit_invoice_are_you_sure message' do
      expect(fake_controller.resubmit_credits_invoice_are_you_sure).to(
        eq <<~STRING.chomp
          Warning... This will recreate the credit's invoice in Mirakl and will overwrite any manual adjustments.
          ID's shown below:
          9
          8
          7
      STRING
      )
    end
  end
end

class FakeStockLocationsController < ApplicationController
  include Spree::Admin::MiraklStockLocationsHelper

  attr_accessor :stock_location
end
