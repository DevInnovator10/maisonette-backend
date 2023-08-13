# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MailHelper do
  before do
    allow(Rails.application.secrets).to receive(:base_url).and_return('https://www.maisonette.com')
    allow(Rails.application.secrets).to receive(:store_phone).and_return('844-MAISONETTE')
    allow(Rails.application.secrets).to receive(:store_email).and_return('customercare@maisonette.com')
  end

  describe '#store_email' do
    it 'returns the store contact email' do
      expect(helper.store_email).to eq 'customercare@maisonette.com'
    end
  end

  describe '#store_phone' do
    it 'returns the store phone number' do
      expect(helper.store_phone).to eq '844-MAISONETTE'
    end
  end

  describe '#mail_subject' do
    it "concatenates 'Maisonette | ' with the input" do
      expect(helper.mail_subject('foo')).to eq 'Maisonette | foo'
    end
  end

  describe '#mail_url' do
    it 'returns the input if it begins with the base_url' do
      expect(helper.mail_url('http://localhost:7777/foo')).to eq "#{Maisonette::Config.fetch('base_url')}/foo"
    end

    it 'adds the base url to the input if not supplied' do
      expect(helper.mail_url('/foo')).to eq "#{Maisonette::Config.fetch('base_url')}/foo"
    end
  end

  describe '#mail_product_image' do
    let(:product) { instance_double Spree::Product, gallery: gallery }
    let(:gallery) { instance_double 'gallery', images: [image] }

    let(:image) { build_stubbed :image }
    let(:image_url) { image.attachment.url(:small) }

    it 'returns the image url from assets cdn' do
      expect(helper.mail_product_image(product)).to eq image_url
    end

    context 'when there are no images' do
      before { allow(gallery).to receive(:images).and_return [] }

      it 'returns an empty string' do
        expect(helper.mail_product_image(product)).to eq ''
      end
    end
  end

  describe '#display_option_values' do
    subject(:display_option_values) do
      helper.display_option_values(option_values) do |ov|
        <<~HTML
          <font>#{ov.option_type.presentation}</font>
          <font>#{ov.presentation}</font>"
        HTML
      end
    end

    let(:option_values) { [option_value_pos_2, option_value_pos_1] }
    let(:option_value_pos_1) { instance_double Spree::OptionValue, option_type: option_type1, presentation: 'Size' }
    let(:option_value_pos_2) { instance_double Spree::OptionValue, option_type: option_type2, presentation: 'Color' }
    let(:option_type1) { instance_double Spree::OptionType, position: 1, presentation: 'Size' }
    let(:option_type2) { instance_double Spree::OptionType, position: 2, presentation: 'Color' }

    it 'returns an ordered list of the given option values' do
      expect(display_option_values).to eq "Size\nSize\"\nColor\nColor\"\n"
    end
  end
end
