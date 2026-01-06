# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::HistoricalOrderPresenter do
  describe '#payload' do
    subject(:payload) do
      described_class.new(order).payload
    end

    let(:order) do
      build_stubbed(:completed_order_with_totals,

                    completed_at: Time.current,
                    gift_email: 'gift@email.com',
                    gift_message: 'surprise',
                    is_gift: true,
                    maisonette_customer: build(:maisonette_customer, id: '1'))
    end
    let(:promotion) { build_stubbed(:adjustment, eligible: true, source_type: 'Spree::PromotionAction', amount: 5) }
    let(:coupon) { build_stubbed(:promotion, codes: [code]) }
    let(:code) { build_stubbed(:promotion_code, value: 'test') }
    let(:expected_payload) do
      {
        AccountId: order.maisonette_customer.id,
        BillingCity: order.billing_address.city,
        BillingCountry: order.billing_address.country.iso,
        BillingEmailAddress: order.email,
        BillingPhoneNumber: order.billing_address.phone,
        BillingPostalCode: order.billing_address.zipcode,
        BillingState: order.billing_address.state.name,
        BillingStreet: order.billing_address.address1,
        EffectiveDate: order.completed_at,
        EndDate: order.completed_at,
        GrandTotalAmount: order.total.to_f,
        OrderedDate: order.completed_at,
        Order_Number__c: order.number,
        ShippingCity: order.shipping_address.city,
        ShippingCountry: order.shipping_address.country.iso,
        ShippingPostalCode: order.shipping_address.zipcode,
        ShippingState: order.shipping_address.state.name,
        ShippingStreet: order.shipping_address.address1,
        Status: order.state,
        Channel__c: order.channel,
        Gift_Email__c: order.gift_email,
        Gift_Message__c: order.gift_message,
        Is_Gift__c: order.is_gift?,
        Giftcard_Total: order.gift_card_adjustments_total.to_f,
        Giftwrap_Total: order.giftwrap_amount,
        Shipping_Total: order.shipment_total,
        Order_Promotion_Total: order.adjustments.eligible.promotion.sum(:amount),
        Coupon_Code__c: coupon_codes,
        Guest_Checkout__c: order.guest_checkout?,
        Environment__c: Rails.env
      }
    end
    let(:coupon_codes) do
      Spree::PromotionCode.where(promotion_id: order.promotions.coupons.applied.pluck(:id)).pluck(:value).join(', ')
    end
    let(:adjustments) { class_double(Spree::Adjustment) }
    let(:promotions) { class_double(Spree::Promotion, applied: [coupon]) }

    before do
      allow(order).to receive(:giftwrap_amount).and_return(5)
      allow(order).to receive(:adjustments).and_return(adjustments)
      allow(order).to receive(:gift_card_adjustments_total).and_return(10)
      allow(adjustments).to receive(:eligible).and_return(adjustments)
      allow(adjustments).to receive(:promotion).and_return(adjustments)
      allow(adjustments).to receive(:sum).with(:amount).and_return(10)
      allow(order).to receive(:promotions).and_return(promotions)
      allow(promotions).to receive(:coupons).and_return(promotions)
      allow(Spree::PromotionCode).to receive(:where).with(promotion_id: [coupon.id]).and_return([code])
    end

    it 'returns the order payload' do
      expect(payload).to eq expected_payload
    end
  end
end
