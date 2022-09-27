# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Jifiti::RefundShippedOrderInteractor do
  describe '#call' do
    subject(:described_method) { described_class.call }

    it { expect(described_method).to be_failure }

    context 'when order is provided' do
      subject(:described_method) { described_class.call(order: order) }

      let(:order) { build_stubbed(:order) }

      it { expect(described_method).to be_failure }
    end

    context 'when order with jifiti information is provided' do
      subject(:described_method) { described_class.call(order: order, amount: 10) }

      let(:jifiti_instructions) do
        "external_source: Jifiti Registry \r\njifiti_receiver_email: #{user_email} \r\n" \
        "jifiti_buyer_email: buyer@maisonette.com \r\njifiti_buyer_name: John Doe \r\n" \
        'jifiti_order_id: 123456'
      end
      let(:user_email) { 'receiver_user@example.com' }
      let(:order) { build_stubbed(:order, :jifiti, special_instructions: jifiti_instructions) }
      let(:jifiti_admin_user) { create(:user, email: 'jifiti@maisonette.com') }

      before do
        jifiti_admin_user

        create(:store_credit_category, name: 'Item Refund')
        create(:secondary_credit_type)

        allow(Sentry).to receive(:capture_exception_with_message)
        allow(Jifiti::RefundMailer).to receive(:error_refund_shipped_order)
      end

      context 'when there are no user with the email provided by jifiti' do
        it 'notify the exception on sentry and to maisonette customer care' do
          expect(described_method).to be_success

          expect(Sentry).to(
            have_received(:capture_exception_with_message).with(instance_of(ActiveRecord::RecordInvalid))
          )
          expect(Jifiti::RefundMailer).to have_received(:error_refund_shipped_order)
        end
      end

      context 'when there is at least one user with the jifiti_receiver_email' do
        let(:user) { create(:user, email: user_email) }

        it 'adds a store credit to the user user specified by jifiti' do
          expect { described_method }.to change { user.store_credits.count }.from(0).to(1)

          expect(user.store_credits.first.amount).to eq 10
          expect(Sentry).not_to have_received(:capture_exception_with_message)
          expect(Jifiti::RefundMailer).not_to have_received(:error_refund_shipped_order)
        end
      end
    end
  end
end
