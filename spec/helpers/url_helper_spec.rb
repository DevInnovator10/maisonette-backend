# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UrlHelper do
  describe '#product_url' do
    subject(:described_method) { helper.product_url(product) }

    let(:product) { build_stubbed :product, slug: slug }
    let(:product_path) { '/prods' }
    let(:slug) { 'a-nice-slug' }

    before do
      allow(ActionMailer::Base.default_url_options).to receive(:[]).with(:host).and_return ''
      allow(Maisonette::Config).to receive(:fetch).with('product_path').and_return(product_path)
    end

    it { expect(described_method).to start_with product_path }
    it { expect(described_method).to include slug }

    context 'with an host set in ActionMailer default options' do
      before { allow(ActionMailer::Base.default_url_options).to receive(:[]).with(:host).and_return(host) }

      let(:host) { 'some.host' }

      it { expect(described_method).to start_with host }
    end
  end

  describe '#order_url' do
    subject(:described_method) { helper.order_url(order) }

    let(:order) { build_stubbed :order, number: order_number }
    let(:order_number) { 'R1234' }
    let(:orders_path) { '/orders' }
    let(:order_token_param) { "?order_token=#{order.guest_token}" }

    before do
      allow(ActionMailer::Base.default_url_options).to receive(:[]).with(:host).and_return ''
      allow(Maisonette::Config).to receive(:fetch).with('orders_path').and_return orders_path
    end

    it { expect(described_method).to start_with orders_path }
    it { expect(described_method).to include order_number }
    it { expect(described_method).to include order_token_param }

    context 'with an host set in ActionMailer default options' do
      before { allow(ActionMailer::Base.default_url_options).to receive(:[]).with(:host).and_return(host) }

      let(:host) { 'some.host' }

      it { expect(described_method).to start_with host }
    end
  end
end
