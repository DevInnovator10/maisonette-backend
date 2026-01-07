# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::PromotionHandler::Coupon::Base, type: :model do
  let(:described_class) { Spree::PromotionHandler::Coupon }

  let(:coupon_handler) { described_class.new(order) }
  let(:order) { create(:order).tap { |o| o.coupon_code = promotion_code.value } }

  let(:promotion) { create(:promotion, :with_order_adjustment) }
  let(:promotion_code) { create :promotion_code, promotion: promotion }

  describe '#apply' do
    context 'when a promotion_code is inactive' do
      before do
        allow(coupon_handler).to receive(:promotion_code).and_return promotion_code
        allow(promotion_code).to receive(:inactive?).and_return true
      end

      it 'sets the proper error code' do
        coupon_handler.apply
        expect(coupon_handler.error).to eq I18n.t('spree.coupon_code_expired')
      end
    end

    context 'when the promotion is inactive' do
      before do
        allow(coupon_handler).to receive(:promotion_code).and_return promotion_code
        allow(promotion).to receive(:active?).and_return(false)
      end

      it 'sets the proper error code' do
        coupon_handler.apply
        expect(coupon_handler.error).to eq I18n.t('spree.coupon_code_expired')
      end
    end

    context 'when promotion is valid' do
      context 'with order in payment state' do
        let(:order) { create(:order_ready_for_payment).tap { |o| o.coupon_code = promotion_code.value } }

        it 'sets the coupon code not found' do
          coupon_handler.apply
          expect(coupon_handler).to be_successful
        end
      end

      context 'with order in delivery state' do
        let(:order) { create(:order_ready_for_payment).tap { |o| o.coupon_code = promotion_code.value } }

        before { order.update(state: 'delivery') }

        it 'sets the coupon code not found' do
          coupon_handler.apply
          expect(coupon_handler).to be_successful
        end

        context 'when order has gift wrapping' do
          before do
            shipment = order.shipments.first
            allow(shipment).to receive(:giftwrappable?).and_return(true)
            shipment.build_giftwrap.save!
          end

          it 'does not reset gift wrapping adjustment data' do
            adjustment_ids = order.giftwrap_adjustments.pluck(:id)
            expect(adjustment_ids.present?).to be true
            coupon_handler.apply
            expect(coupon_handler).to be_successful

            order.reload
            expect(order.giftwrap_adjustments.pluck(:id)).to match adjustment_ids
          end
        end
      end

      context 'with order in address state' do
        let(:order) { create(:order_ready_for_payment).tap { |o| o.coupon_code = promotion_code.value } }

        before { order.update(state: 'address') }

        it 'sets the coupon code not found' do
          coupon_handler.apply
          expect(coupon_handler).not_to be_successful
          expect(coupon_handler.error).to eq I18n.t('spree.coupon_code_activation')
        end
      end

      context 'with order in complete state' do
        let(:order) { create(:order_ready_for_payment).tap { |o| o.coupon_code = promotion_code.value } }

        before { order.update(state: 'complete', completed_at: Time.current) }

        it 'sets the coupon code not found' do
          coupon_handler.apply
          expect(coupon_handler).not_to be_successful
          expect(coupon_handler.error).to eq I18n.t('spree.coupon_code_activation')
        end

        context 'when coupon_handler is set as simulate' do
          before do
            coupon_handler.instance_variable_set(:@simulate, true)
          end

          it 'applies the coupon anyway' do
            coupon_handler.apply

            expect(coupon_handler).to be_successful
            expect(coupon_handler.error).not_to eq I18n.t('spree.coupon_code_activation')
          end
        end
      end

      context 'with order in confirm state' do
        let(:order) { create(:order_ready_to_complete).tap { |o| o.coupon_code = promotion_code.value } }

        it 'sets the coupon code not found' do
          coupon_handler.apply
          expect(coupon_handler).not_to be_successful
          expect(coupon_handler.error).to eq I18n.t('spree.coupon_code_activation')
        end
      end
    end

    context 'when a promotion_code is not found' do
      let(:order) { create(:order_ready_for_payment).tap { |o| o.coupon_code = 'abcd' } }

      it 'sets the coupon code not found' do
        coupon_handler.apply
        expect(coupon_handler.error).to eq I18n.t('spree.coupon_code_not_found')
      end
    end
  end
end
