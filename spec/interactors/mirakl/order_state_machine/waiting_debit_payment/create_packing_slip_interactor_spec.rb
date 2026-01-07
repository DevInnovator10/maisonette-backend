# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::OrderStateMachine::WaitingDebitPayment::CreatePackingSlipInteractor, mirakl: true do
  describe 'call' do
    subject(:call) { interactor.call }

    let(:interactor) { described_class.new(mirakl_order: mirakl_order) }
    let(:mirakl_order) { instance_double Mirakl::Order, shipment: shipment, logistic_order_id: 'R123-A' }
    let(:shipment) { instance_double Spree::Shipment }
    let(:binary_pdf_file) { 'im a pdf file' }
    let(:html_to_s) { '<h1> Hello World! </h1> ' }
    let(:pdf_binary) { 'pdf binary' }
    let(:wicked_pdf) { instance_double WickedPdf, pdf_from_string: pdf_binary }

    before do
      allow(interactor).to receive_messages(render_to_string: html_to_s)
      allow(WickedPdf).to receive_messages(new: wicked_pdf)
      allow(Mirakl::BinaryFileStringIO).to receive_messages(new: binary_pdf_file)
    end

    context 'when it is successful' do
      before { call }

      it 'add context binary_file' do
        expect(Mirakl::BinaryFileStringIO).to have_received(:new).with(pdf_binary, 'packing-slip.pdf')
        expect(interactor.context.binary_file).to eq binary_pdf_file
      end

      it 'adds context doc_type' do
        expect(interactor.context.doc_type).to eq MIRAKL_DATA[:order][:documents][:system_delivery_bill]
      end

      it 'calls render_to_string' do
        expect(interactor).to have_received(:render_to_string)
      end

      it 'calls wicked_pdf with packing slip html' do
        expect(wicked_pdf).to have_received(:pdf_from_string).with(html_to_s, dpi: 300)
      end
    end

    context 'when an error is thrown' do
      let(:exception) { StandardError.new 'some error' }

      before do
        allow(interactor).to receive_messages(rescue_and_capture: false)
        allow(WickedPdf).to receive(:new).and_raise(exception)
      end

      it 'does fail the interactor' do
        expect { call }.to raise_exception(Interactor::Failure)

        expect(interactor.context).to be_failure
      end

      it 'calls rescue_and_capture' do
        expect { call }.to raise_exception(Interactor::Failure)

        expect(interactor).to(
          have_received(:rescue_and_capture).with(exception,
                                                  extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        )
      end
    end
  end

  describe '.renter_to_string' do
    let(:spree_order) do
      instance_double(Spree::Order,
                      number: 'R12341',
                      ship_address: ship_address,
                      bill_address: bill_address,
                      completed_at: Date.parse('10/5/2018'),
                      is_gift?: is_gift?,
                      gift_message: gift_message)
    end
    let(:ship_address) do
      instance_double(Spree::Address,
                      full_name: 'Bob Marley',
                      address1: 'bobs address 1',
                      address2: 'bobs address 2',
                      city: 'Beverly Hills',
                      state: instance_double(Spree::State, abbr: 'CA'),
                      zipcode: '90210',
                      country: instance_double(Spree::Country, name: 'United States'),
                      phone: '123456789')
    end
    let(:bill_address) do
      instance_double(Spree::Address,
                      full_name: 'Marilyn Manson',
                      address1: '666 Hell Avn',
                      address2: 'Apt 4.20',
                      city: 'Hells Kitchen',
                      state: nil,
                      zipcode: '32569',
                      country: instance_double(Spree::Country, name: 'Alaska'),
                      phone: '987654321')
    end
    let(:shipment) do
      instance_double(Spree::Shipment,
                      order: spree_order,
                      manifest: [shipment_manifest],
                      giftwrapped?: giftwrapped,
                      giftwrap: giftwrap,
                      total: 10.0)
    end
    let(:giftwrapped) { false }
    let(:giftwrap) { nil }
    # rubocop:disable RSpec/VerifiedDoubles
    let(:shipment_manifest) { double(Struct, line_item: line_item_1, variant: variant_1, quantity: 2) }
    # rubocop:enable RSpec/VerifiedDoubles
    let(:line_item_1_adjustments) { class_double Spree::Adjustment, tax: [tax_adjustment] }
    let(:line_item_1) do
      instance_double(Spree::LineItem,
                      variant: variant_1,
                      sku: 'sku123',
                      name: 'A Coat',
                      price: 1.5,
                      adjustments: line_item_1_adjustments,
                      quantity: 2,
                      product: product,
                      offer_settings: offer_settings_1,
                      final_sale?: true)
    end
    let(:color_taxon) { instance_double Spree::Taxon, name: 'Red' }
    let(:product) { instance_double Spree::Product, color: color_taxon }
    let(:tax_adjustment) { instance_double Spree::Adjustment, amount: 0.5 }
    let(:variant_1) { instance_double Spree::Variant, option_values: [option_value] }
    let(:vendor) { instance_double Spree::Vendor, name: 'Vendor123' }
    let(:offer_settings_1) { instance_double Spree::OfferSettings, vendor_sku: 'VND123', vendor: vendor }
    let(:option_value) { instance_double Spree::OptionValue, name: 'small' }
    let(:mirakl_order) { instance_double Mirakl::Order, shipment: shipment }
    let(:render_to_string) { described_class.new(mirakl_order: mirakl_order).send :render_to_string }
    let(:is_gift?) { false }
    let(:gift_message) {}

    it 'returns ApplicationController.new.render_to_string' do
      expect(render_to_string).to include 'R12341' # order number
      expect(render_to_string).to include '$3.00' # subtotal
      expect(render_to_string).to include '$10.00' # shipping cost
      expect(render_to_string).to include '$0.50' # sales tax
      expect(render_to_string).to include '$13.50' # order total
    end

    it 'contains the product name and colour' do
      expect(render_to_string).to include 'A Coat' # product name
      expect(render_to_string).to include 'Red' # color
    end

    it 'contains the vendor sku' do
      expect(render_to_string).to include 'VND123'
    end

    it 'contains the vendor name' do
      expect(render_to_string).to include 'Vendor123'
    end

    it 'contains final sale info' do
      expect(render_to_string).to include '- Final Sale'
    end

    it 'contains the return policy' do
      # rubocop:disable Layout/LineLength
      expect(render_to_string).to include(
        'We offer easy returns within 30 days of the delivery date for a full refund, less a $5.00 return fee per shipment. We accept returns for eligible items that are unworn, undamaged, and with tags still attached. Final sale and other non-returnable items may not be returned or exchanged. These items are marked as “Final Sale” at checkout as well as on this page.'
      )
      # rubocop:enable Layout/LineLength
      expect(render_to_string).to include(
        'Holiday Returns Policy: Eligible items purchased between November 1 and December 15'
      )
      expect(render_to_string).to include(
        'Do you have other questions about your order? Our Customer Concierge team is here to help!'
      )
    end

    it "doesn't contain the Gift Wrapped message" do
      expect(render_to_string).not_to include 'Gift Wrapped'
    end

    context 'when it is a gift' do
      let(:is_gift?) { true }
      let(:gift_message) { 'im a gift' }

      it 'contains the gift message and no amounts' do
        expect(render_to_string).to include 'im a gift'
        expect(render_to_string).not_to include '$3.00'
      end
    end

    context 'when shipment is gift wrapped' do
      let(:giftwrapped) { true }
      let(:giftwrap) do
        instance_double(Maisonette::Giftwrap,
                        giftwrap_total: 2.50)
      end

      it 'contains the Gift Wrapped message' do
        expect(render_to_string).to include 'Gift Wrapped'
      end

      it 'contains the shipping cost without the giftwrap cost' do
        expect(render_to_string).to include '$7.50'
      end

      it 'contains the giftwrap cost' do
        expect(render_to_string).to include '$2.50'
      end
    end
  end
end
