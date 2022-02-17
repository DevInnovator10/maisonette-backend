# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::Order::CustomsForm, mirakl: true do
  describe '#send_customs_form' do
    let(:fake_parcel) { FakeParcel.new }
    let(:shipment) { instance_double(Spree::Shipment, mirakl_order: mirakl_order) }
    let(:mirakl_order) { instance_double(Mirakl::Order) }
    # rubocop:disable RSpec/VerifiedDoubles
    let(:easypost_shipment) { double(EasyPost::Shipment, forms: forms) }
    let(:forms) { [customs_form] }
    let(:customs_form) { double(EasyPost::EasyPostObject, form_type: form_type) }
    # rubocop:enable RSpec/VerifiedDoubles
    let(:form_type) { EASYPOST_DATA[:forms][:customs] }
    let(:customs_form_label) { MIRAKL_DATA[:order][:documents][:customs_form] }
    let(:binary_file) { instance_double Mirakl::BinaryFileStringIO }

    before do
      allow(fake_parcel).to receive_messages(spree_shipment: shipment,
                                             master_easypost_shipment: easypost_shipment,
                                             customs_form_binary_file: binary_file)
      allow(Mirakl::SubmitOrderDocInteractor).to receive(:call)
      fake_parcel.send_customs_form
    end

    it 'calls Mirakl::SubmitOrderDocInteractor with the customs form file' do
      expect(Mirakl::SubmitOrderDocInteractor).to have_received(:call).with(mirakl_order: mirakl_order,
                                                                            binary_file: binary_file,
                                                                            doc_type: customs_form_label)
    end

    it 'calls customs_form_binary_file with the customs form' do
      expect(fake_parcel).to have_received(:customs_form_binary_file).with(customs_form)
    end

    context 'when there is no form' do
      let(:forms) { [] }

      it 'does not call calls Mirakl::SubmitOrderDocInteractor' do
        expect(Mirakl::SubmitOrderDocInteractor).not_to have_received(:call)
      end
    end
  end

  describe '#customs_info' do
    let(:fake_parcel) { FakeParcel.new }
    let(:customs_info) { EasyPost::CustomsInfo.new }
    let(:us_ship_address) { instance_double(Spree::Address, country: country_us) }
    let(:country_us) { instance_double(Spree::Country, iso: 'US') }
    let(:from_country) { instance_double(Spree::Country, iso: 'US') }
    let(:shipment) { instance_double(Spree::Shipment, order: order, stock_location: stock_location) }
    let(:order) { instance_double(Spree::Order, ship_address: us_ship_address) }
    let(:stock_location) { instance_double(Spree::StockLocation, country: from_country) }

    before do
      allow(fake_parcel).to receive_messages(spree_shipment: shipment)
    end

    context 'when the shipping is domestic' do
      it 'returns nil' do
        expect(fake_parcel.send(:customs_info)).to eq nil
      end
    end

    context 'when the shipping is international' do
      let(:from_country) { build :country, iso: 'GB' }
      let(:customs_item) { 'customs_item' }
      let(:contents_explanation) { 'Sale of some clothes, Sale of some other clothes' }

      before do
        allow(EasyPost::CustomsInfo).to receive_messages(create: customs_info)
        allow(fake_parcel).to receive_messages(customs_items: [customs_item],
                                               contents_explanation: contents_explanation)
      end

      it 'returns EasyPost::CustomsInfo' do
        expect(fake_parcel.send(:customs_info)).to eq customs_info
      end

      it 'creates an EasyPost::CustomsInfo' do
        fake_parcel.send :customs_info
        expect(EasyPost::CustomsInfo).to have_received(:create).with(eel_pfc: 'NOEEI 30.37(a)',
                                                                     customs_certify: false,
                                                                     contents_type: 'merchandise',
                                                                     contents_explanation: contents_explanation,
                                                                     customs_items: [customs_item])
      end
    end
  end

  describe '#contents_explanation' do
    subject(:contents_explanation) { fake_parcel.send(:contents_explanation) }

    let(:fake_parcel) { FakeParcel.new }

    let(:shipment) { instance_double(Spree::Shipment, line_items: line_items) }
    let(:line_items) { [line_item1, line_item2] }
    let(:line_item1) { instance_double Spree::LineItem, product: product1 }
    let(:line_item2) { instance_double Spree::LineItem, product: product2 }
    let(:product1) { instance_double(Spree::Product, taxons: product1_taxons) }
    let(:product2) { instance_double(Spree::Product, taxons: product2_taxons) }
    let(:product1_taxons) { class_double Spree::Taxon }
    let(:product2_taxons) { class_double Spree::Taxon }
    let(:main_category_taxon) { instance_double Spree::Taxon, name: 'Main Category' }
    let(:product_type_taxon) { instance_double Spree::Taxon, name: 'Product Type' }
    let(:product1_main_category_taxon) { instance_double Spree::Taxon, name: 'Apparel' }
    let(:product1_product_type_taxon) { instance_double Spree::Taxon, name: 'Outerwear' }
    let(:product2_main_category_taxon) { instance_double Spree::Taxon, name: 'Play' }
    let(:product2_product_type_taxon) { instance_double Spree::Taxon, name: 'Childrens Dollhouse' }

    before do
      allow(fake_parcel).to receive_messages(spree_shipment: shipment)
      allow(Spree::Taxon).to(
        receive(:find_by).with(name: Spree::Taxonomy::MAIN_CATEGORY).and_return(main_category_taxon)
      )
      allow(Spree::Taxon).to(
        receive(:find_by).with(name: Spree::Taxonomy::PRODUCT_TYPE).and_return(product_type_taxon)
      )
      allow(product1_taxons).to(
        receive(:find_by).with(parent: main_category_taxon).and_return(product1_main_category_taxon)
      )
      allow(product1_taxons).to(
        receive(:find_by).with(parent: product_type_taxon).and_return(product1_product_type_taxon)
      )
      allow(product2_taxons).to(
        receive(:find_by).with(parent: main_category_taxon).and_return(product2_main_category_taxon)
      )
      allow(product2_taxons).to(
        receive(:find_by).with(parent: product_type_taxon).and_return(product2_product_type_taxon)
      )
    end

    it 'returns a string of the line items category and type' do
      expect(contents_explanation).to eq 'Sale of Apparel/Outerwear, Play/Childrens Dollhouse'
    end

    context 'when there are line items with duplicate cateogry/product type combinations' do
      10.times do |i|
        let("line_item#{i + 3}".to_sym) { instance_double Spree::LineItem, product: (i.even? ? product1 : product2) }
      end
      let(:line_items) { (1..10).map { |i| send("line_item#{i}") } }

      it 'removes duplicate values from the string' do
        expect(contents_explanation).to eq 'Sale of Apparel/Outerwear, Play/Childrens Dollhouse'
      end
    end

    context 'when the taxon category names are very long' do
      let(:product1_main_category_taxon) { instance_double Spree::Taxon, name: '-' * 256 }

      it 'limits the contents explanation to 255 characters' do
        expect(contents_explanation.length).to eq 255
      end
    end
  end

  describe '#customs_items' do
    subject(:customs_items) { fake_parcel.send(:customs_items) }

    let(:fake_parcel) { FakeParcel.new }
    let(:shipment) { instance_double(Spree::Shipment, line_items: line_items) }
    let(:line_items) { [line_item1, line_item2] }
    let(:line_item1) { instance_double Spree::LineItem, variant: variant1, quantity: 2, total: 10.0 }
    let(:line_item2) { instance_double Spree::LineItem, variant: variant2, quantity: 1, total: 25.0 }
    let(:variant1) { instance_double(Spree::Variant, name: 'Anna Dress') }
    let(:variant2) { instance_double(Spree::Variant, name: 'Bunnies') }
    let(:uk_country) { instance_double Spree::Country, iso: 'UK' }
    let(:customs_item1) { instance_double(EasyPost::CustomsItem) }
    let(:customs_item2) { instance_double(EasyPost::CustomsItem) }

    before do
      allow(fake_parcel).to receive_messages(spree_shipment: shipment)
      allow(variant1).to receive(:property).with('Tariff Codes').and_return('12345')
      allow(variant1).to receive(:property).with('Box1 Packaged Weight').and_return('1.2')
      allow(variant2).to receive(:property).with('Tariff Codes').and_return('00982')
      allow(variant2).to receive(:property).with('Box1 Packaged Weight').and_return('0.5')
      allow(EasyPost::CustomsItem).to receive(:create).and_return(customs_item1, customs_item2)
    end

    context 'when the Country of Origin is not abbreviated' do
      before do
        allow(variant1).to receive(:property).with('Country of Origin').and_return('United Kingdom')
        allow(variant2).to receive(:property).with('Country of Origin').and_return('United Kingdom')
        allow(Spree::Country).to receive(:find_by).with(name: 'United Kingdom').and_return(uk_country)

        customs_items
      end

      it 'returns an array of customs_items for each line item' do
        expect(customs_items).to eq [customs_item1, customs_item2]
      end

      it 'calls create on EasyPost::CustomsItem' do
        expect(EasyPost::CustomsItem).to have_received(:create).with(description: variant1.name,
                                                                     quantity: line_item1.quantity,
                                                                     value: line_item1.total,
                                                                     weight: 38.4,
                                                                     hs_tariff_number: '12345',
                                                                     origin_country: 'UK')
        expect(EasyPost::CustomsItem).to have_received(:create).with(description: variant2.name,
                                                                     quantity: line_item2.quantity,
                                                                     value: line_item2.total,
                                                                     weight: 8,
                                                                     hs_tariff_number: '00982',
                                                                     origin_country: 'UK')
      end
    end

    context 'when the Country of Origin is abbreviated' do
      before do
        allow(variant1).to receive(:property).with('Country of Origin').and_return('UK')
        allow(variant2).to receive(:property).with('Country of Origin').and_return('UK')
        allow(Spree::Country).to receive(:find_by).with(name: 'UK').and_return(nil)
        allow(Spree::Country).to receive(:find_by).with(iso_name: 'UK').and_return(nil)
        allow(Spree::Country).to receive(:find_by).with(iso: 'UK').and_return(uk_country)

        customs_items
      end

      it 'returns an array of customs_items for each line item' do
        expect(customs_items).to eq [customs_item1, customs_item2]
      end

      it 'calls create on EasyPost::CustomsItem' do
        expect(EasyPost::CustomsItem).to have_received(:create).with(description: variant1.name,
                                                                     quantity: line_item1.quantity,
                                                                     value: line_item1.total,
                                                                     weight: 38.4,
                                                                     hs_tariff_number: '12345',
                                                                     origin_country: 'UK')
        expect(EasyPost::CustomsItem).to have_received(:create).with(description: variant2.name,
                                                                     quantity: line_item2.quantity,
                                                                     value: line_item2.total,
                                                                     weight: 8,
                                                                     hs_tariff_number: '00982',
                                                                     origin_country: 'UK')
      end
    end
  end

  describe '#customs_form_binary_file' do
    subject(:customs_form_binary_file) { fake_parcel.send :customs_form_binary_file, customs_form }

    let(:fake_parcel) { FakeParcel.new }
    # rubocop:disable RSpec/VerifiedDoubles
    let(:customs_form) { double(EasyPost::EasyPostObject, form_url: form_url, id: form_id) }
    # rubocop:enable RSpec/VerifiedDoubles
    let(:customs_form_response) { instance_double RestClient::Response, body: customs_form_string }
    let(:customs_form_string) { 'some customs form data' }
    let(:form_url) { 'www.easypost.com/customs_forms/01' }
    let(:form_id) { 'form_id_01' }
    let(:file_name) { "customs_form_#{form_id}.pdf" }
    let(:binary_file) { instance_double Mirakl::BinaryFileStringIO }

    before do
      allow(RestClient).to receive(:get).with(customs_form.form_url).and_return(customs_form_response)
      allow(Mirakl::BinaryFileStringIO).to receive_messages(new: binary_file)

      customs_form_binary_file
    end

    it 'calls Mirakl::BinaryFileStringIO.new with the customs form string and file name' do
      expect(Mirakl::BinaryFileStringIO).to have_received(:new).with(customs_form_string, file_name)
    end

    it 'returns a Mirakl::BinaryFileStringIO' do
      expect(customs_form_binary_file).to eq binary_file
    end
  end
end

class FakeParcel
  attr_reader :spree_shipment, :master_easypost_shipment

  include Easypost::Order::CustomsForm
end
