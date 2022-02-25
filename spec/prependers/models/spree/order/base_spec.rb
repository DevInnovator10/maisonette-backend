# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order::Base, type: :model do
  let(:described_class) { Spree::Order }

  it { is_expected.to have_db_column(:is_gift) }
  it { is_expected.to have_db_column(:gift_email) }
  it { is_expected.to have_db_column(:gift_message) }

  it { is_expected.to belong_to(:maisonette_customer).class_name('Maisonette::Customer').optional }
  it { is_expected.to have_many(:applied_promotion_codes).source(:promotion_code).through(:all_adjustments) }

  describe 'applied_promotion_codes' do
    let(:promo_code) { create :promotion_code, value: 'foo', promotion: promotion }
    let(:promo_code_response) { json_response[:applied_promotion_codes] }
    let(:promotion) do
      create(:promotion).tap { |promo| Spree::Promotion::Actions::CreateItemAdjustments.create!(promotion: promo) }
    end
    let(:order) { create :order_with_line_items, line_items_count: 2 }

    before do
      order.line_items.each do |li|
        create :adjustment, adjustable: li, source: promotion.actions.first, promotion_code: promo_code, order: order
      end
    end

    it 'only returns one applied promotion' do
      expect(order.applied_promotion_codes.length).to eq 1
    end
  end

  describe 'validations' do
    before { order.valid? }

    context 'when a gift_email is provided' do
      context 'when the email is valid' do
        let(:order) { described_class.new(gift_email: 'foo@bar.com') }

        it 'does not return errors on the order' do
          expect(order.errors.keys).not_to include :gift_email
        end
      end

      context 'when the email is invalid' do
        let(:order) { described_class.new(gift_email: 'foo') }

        it 'returns errors on the order' do
          expect(order.errors.keys).to include :gift_email
          expect(order.errors[:gift_email]).to include 'is invalid'
        end
      end
    end

    context 'when a gift_email is not provided' do
      let(:order) { described_class.new }

      it 'does not return errors on gift email' do
        expect(order.errors.keys).not_to include :gift_email
      end
    end
  end

  describe '#to_s' do
    let(:attrs) { { number: '1234', state: 'paid', email: 'foo@example.com', total: 100 } }
    let(:order) { described_class.new(attrs) }

    it 'returns early if no number' do
      order = described_class.new(attrs.except(:number))
      allow(order).to receive(:state)
      order.to_s
      expect(order).not_to have_received(:state)
    end

    it 'is a string' do
      expect(order.to_s).to be_a(String)
    end

    it 'returns the order number, state, email, and total' do
      expect(order.to_s).to eq '1234(paid) - foo@example.com - $100.00'
    end

    it 'returns neither state or email if both are empty' do
      order.state = nil
      order.email = nil
      expect(order.to_s).to eq '1234 - $100.00'
    end

    it 'does not return a state if it is not present' do
      order.state = nil
      expect(order.to_s).to eq '1234 - foo@example.com - $100.00'
    end

    it 'does not return an empty email string if email is blank' do
      order.email = nil
      expect(order.to_s).to eq '1234(paid) - $100.00'
    end
  end

  describe '#eligible_promotion_adjustments' do
    let(:order) { create(:order_with_line_items, :with_promotion) }
    let(:promotion_action) { order.promotions.first.actions.first }

    let(:promotion_adjustment) do
      create(:adjustment, source: promotion_action, order: order, adjustable: order.line_items.first)
    end
    let(:non_promotion_adjustment) { create(:adjustment, order: order, source_type: 'Spree::TaxRate') }
    let(:non_eligible_promotion_adjustment) do
      create(:adjustment, source: promotion_action, order: order, eligible: false)
    end

    before do
      promotion_adjustment
      non_promotion_adjustment
      non_eligible_promotion_adjustment
    end

    it 'is an active record relation' do
      expect(order.eligible_promotion_adjustments).to be_a ActiveRecord::Relation
    end

    it 'includes eligible promotion adjustments' do
      expect(order.eligible_promotion_adjustments).to include promotion_adjustment
    end

    it 'does not include non promotion adjustments' do
      expect(order.all_adjustments).to include non_promotion_adjustment
      expect(order.eligible_promotion_adjustments).not_to include non_promotion_adjustment
    end

    it 'does not include non eligible adjustments' do
      expect(order.all_adjustments).to include non_eligible_promotion_adjustment
      expect(order.eligible_promotion_adjustments).not_to include non_eligible_promotion_adjustment
    end
  end

  describe '#post_to_sales_feed' do
    let(:order) { build_stubbed :order }

    before do
      allow(Spree::OrderSlackNotifyWorker).to receive(:perform_async)
      order.send :post_to_sales_feed
    end

    it 'notifies slack' do
      expect(Spree::OrderSlackNotifyWorker).to(
        have_received(:perform_async).with(order.number)
      )
    end
  end

  describe '#slack_notification_message' do
    subject { order.slack_notification_message }

    let(:order) { create :order_with_line_items, line_items_count: 2 }

    it { is_expected.to include order.edit_admin_url }
    it { is_expected.to include order.line_items.first.variant.name }
  end

  describe '#edit_admin_url' do
    subject(:described_method) { order.edit_admin_url }

    let(:order) { build_stubbed :order }
    let(:admin_url) { 'foo_bar' }

    before do
      allow(Maisonette::Config).to receive(:fetch).with('admin_url').and_return admin_url
      described_method
    end

    it 'returns the admin_url from config' do
      expect(Maisonette::Config).to have_received(:fetch).with('admin_url')
    end

    it 'returns the full url' do
      expect(described_method).to eq "#{admin_url}/admin/orders/#{order.number}/edit"
    end
  end

  describe 'state machine callbacks' do
    context 'when after transitioning to delivery' do
      let(:order) { create :order_with_line_items, state: :address }

      before do
        allow(Spree::PromotionHandler::Shipping).to receive(:new).and_call_original
      end

      it 'applies shipping promotions' do
        expect { order.next! }.to change(order, :state).from('address').to('delivery')
        expect(Spree::PromotionHandler::Shipping).to have_received(:new).with(order).once
      end
    end

    context 'when transitioning to complete' do
      let(:order) { create :order_ready_to_complete }

      before do
        allow(order).to receive(:post_to_sales_feed)
      end

      it 'calls #post_to_sales_feed' do
        order.complete!
        expect(order).to have_received(:post_to_sales_feed)
      end
    end
  end

  describe '#legacy_order?' do
    subject { order.legacy_order? }

    context 'when prefixed with R' do
      let(:order) { build :order, number: 'R100' }

      it { is_expected.to be_truthy }
    end

    context 'when prefixed with M' do
      let(:order) { build :order, number: 'M100' }

      it { is_expected.to be_falsey }
    end
  end

  describe '#guest_checkout?' do
    subject { order.guest_checkout? }

    context 'when order has a registered user' do
      let(:order) { build :order, user: build(:user) }

      it { is_expected.to be_falsey }
    end

    context 'when order does not have a registered user' do
      let(:order) { build :order, user: nil }

      it { is_expected.to be_truthy }
    end
  end

  describe '#maisonette_customer' do
    subject { user.maisonette_customer }

    let(:not_completed_order) { create :order, user: user }
    let(:user) { create :user }

    before do
      not_completed_order
    end

    it { is_expected.to be nil }

    context 'when the user has at least one completed order' do
      before do
        completed_order
      end

      let(:completed_order) { create :completed_order_with_totals, user: user, maisonette_customer: nil }

      it { is_expected.to be nil }

      context 'when maisonette_customer is present' do
        let(:completed_order) do
          create :completed_order_with_totals, user: user, maisonette_customer: maisonette_customer
        end
        let(:maisonette_customer) { create(:maisonette_customer) }

        it { is_expected.to eq maisonette_customer }
      end
    end
  end

  describe '#recompute_shipping' do
    let(:order) { create :order_with_line_items, line_items_count: 2 }

    before do
      allow(order).to receive(:apply_shipping_promotions)
      allow(order).to receive(:reload).and_return(order)
    end

    it 'reapplies shipping adjustments' do
      order.recompute_shipping
      expect(order).to have_received(:apply_shipping_promotions)
      expect(order).to have_received(:reload)
    end
  end
end
