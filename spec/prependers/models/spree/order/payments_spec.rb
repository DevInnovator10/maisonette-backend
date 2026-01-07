# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order::Payments, type: :model do
  let(:described_class) { Spree::Order }

  describe '#recalculate_payments' do
    subject(:recalculate_payments!) { order.recalculate_payments }

    let(:order_total) { 500.00 }

    before { create(:store_credit_payment_method) }

    context 'when there is no store credit' do
      let(:order) { create(:order, total: order_total, use_store_credits: true) }

      context 'when there is a credit card payment' do
        before do
          create(:payment, order: order, amount: order_total)

          # callbacks recalculate total based on line items
          # this ensures the total is what we expect
          order.update_column(:total, order_total)
          recalculate_payments!
          order.reload
        end

        it 'charges the outstanding balance to the credit card' do
          expect(order.errors.messages).to be_empty
          expect(order.payments.count).to eq 1
          expect(order.payments.first.source).to be_a(Spree::CreditCard)
          expect(order.payments.first.amount).to eq order_total
        end
      end
    end

    context 'when there is store credit in another currency' do
      let(:order) do
        create(
          :order_with_totals,
          user: user,
          line_items_price: order_total,
          use_store_credits: true
        ).tap(&:recalculate)
      end
      let!(:store_credit_usd) { create(:store_credit, user: user, amount: 1, currency: 'USD') }
      let(:user) { create(:user) }

      before { create(:store_credit, user: user, amount: 1, currency: 'GBP') }

      it 'only adds the credit in the matching currency' do
        expect do
          recalculate_payments!
        end.to change {
          order.payments.count
        }.by(1)

        applied_store_credits = order.payments.store_credits.map(&:source)
        expect(applied_store_credits).to match_array([store_credit_usd])
      end
    end

    context 'when there is enough store credit to pay for the entire order' do
      let(:store_credit) { create(:store_credit, amount: order_total) }
      let(:order) do
        create(
          :order_with_totals,
          use_store_credits: true,
          user: store_credit.user,
          line_items_price: order_total
        ).tap(&:recalculate)
      end

      context 'when there are no other payments' do
        before do
          recalculate_payments!
          order.reload
        end

        it 'creates a store credit payment for the full amount' do
          expect(order.errors.messages).to be_empty
          expect(order.payments.count).to eq 1
          expect(order.payments.first).to be_store_credit
          expect(order.payments.first.amount).to eq order_total
        end
      end

      context 'when there is a credit card payment' do
        it 'invalidates the credit card payment' do
          cc_payment = create(:payment, order: order)
          expect { recalculate_payments! }.to change { cc_payment.reload.state }.to 'invalid'
        end

        context "when the order doesn't use store credits" do
          let(:order) do
            create(:order_with_totals,
                   use_store_credits: false,
                   user: store_credit.user,
                   line_items_price: order_total).tap(&:recalculate)
          end

          it "doesn't invalidates the credit card payment" do
            cc_payment = create(:payment, order: order)
            expect { recalculate_payments! }.not_to(change { cc_payment.reload.state })
          end
        end
      end
    end

    context 'when the available store credit is not enough to pay for the entire order' do
      let(:order_total) { 500 }
      let(:store_credit_total) { order_total - 100 }
      let(:store_credit)       { create(:store_credit, amount: store_credit_total) }
      let(:order) do
        create(
          :order_with_totals,
          use_store_credits: true,
          user: store_credit.user,
          line_items_price: order_total
        ).tap(&:recalculate)
      end

      context 'when there are no other payments' do
        it 'adds an error to the model' do
          expect(recalculate_payments!).to be false
          expect(order.errors.full_messages).to include(I18n.t('spree.store_credit.errors.unable_to_fund'))
        end
      end

      context 'when there is a completed credit card payment' do
        before do
          create(:payment, order: order, state: 'completed', amount: 100)
        end

        it 'successfully creates the store credit payments' do
          expect { recalculate_payments! }.to change { order.payments.count }.from(1).to(2)
          expect(order.errors).to be_empty
        end
      end

      context 'when there is a credit card payment' do
        before do
          create(:payment, order: order, state: 'checkout')

          recalculate_payments!
        end

        it 'charges the outstanding balance to the credit card' do
          expect(order.errors.messages).to be_empty
          expect(order.payments.count).to eq 2
          expect(order.payments.first.source).to be_a(Spree::CreditCard)
          expect(order.payments.first.amount).to eq 100
        end

        # see associated comment in order_decorator#recalculate_payments
        context 'when the store credit is already in the pending state' do
          before do
            order.payments.store_credits.last.authorize!
            order.recalculate_payments
          end

          it 'charges the outstanding balance to the credit card' do
            expect(order.errors.messages).to be_empty
            expect(order.payments.count).to eq 2
            expect(order.payments.first.source).to be_a(Spree::CreditCard)
            expect(order.payments.first.amount).to eq 100
          end
        end
      end
    end

    context 'when there are multiple store credits' do
      context 'when they have different credit type priorities' do
        let(:amount_difference)       { 100 }
        let!(:primary_store_credit)   { create(:store_credit, amount: (order_total - amount_difference)) }
        let!(:secondary_store_credit) do
          create(
            :store_credit,
            amount: order_total,
            user: primary_store_credit.user,
            credit_type: create(:secondary_credit_type)
          )
        end
        let(:order) do
          create(
            :order_with_totals,
            use_store_credits: true,
            user: primary_store_credit.user,
            line_items_price: order_total
          ).tap(&:recalculate)
        end

        before do
          recalculate_payments!
          order.reload
        end

        it 'uses the primary store credit type over the secondary' do
          primary_payment = order.payments.detect { |x| x.source == primary_store_credit }
          secondary_payment = order.payments.detect { |x| x.source == secondary_store_credit }

          expect(order.payments.size).to eq 2
          expect(primary_payment.source).to eq primary_store_credit
          expect(secondary_payment.source).to eq secondary_store_credit
          expect(primary_payment.amount).to eq(order_total - amount_difference)
          expect(secondary_payment.amount).to eq(amount_difference)
        end
      end
    end
  end
end
