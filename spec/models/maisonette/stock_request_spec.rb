# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::StockRequest, type: :model do
  it { is_expected.to belong_to :variant }
  it { is_expected.to delegate_method(:product).to :variant }

  describe 'validations' do
    it { is_expected.to validate_presence_of :email }

    context 'with an invalid email' do
      subject { described_class.new email: 'invalid' }

      it { is_expected.not_to be_valid }
    end

    context 'with a valid email' do
      subject(:validate_email) { described_class.new email: email, variant: variant, state: :requested }

      let(:email) { FFaker::Internet.email }
      let(:variant) { build_stubbed :variant }

      it { is_expected.to be_valid }

      context 'when the email is already in use' do
        before do
          create :stock_request, email: email, variant: variant, state: :requested
        end

        it 'raises a EmailAlreadyOnWaitlistException' do
          expect { validate_email.validate }.to(
            raise_exception(described_class::EmailAlreadyOnWaitlistException,
                            'Email is already on the waitlist for this product.')
          )
        end
      end
    end
  end

  describe 'scopes' do
    let(:requested) { create_list :stock_request, 1, state: :requested }
    let(:queued) { create_list :stock_request, 1, state: :queued }
    let(:notified) { create_list :stock_request, 1, state: :notified }

    before { requested && queued && notified }

    describe '.requested' do
      it { expect(described_class.requested).to match_array requested }
    end

    describe '.queued' do
      it { expect(described_class.queued).to match_array queued }
    end

    describe '.notified' do
      it { expect(described_class.notified).to match_array notified }
    end

    describe '.with_purchasable_variant' do
      let(:variant) { create :variant, :in_stock, :with_multiple_prices }
      let(:purchasable) { create :stock_request, variant: variant }

      context 'when variant is purchasable' do
        it { expect(described_class.with_purchasable_variant).to match_array [purchasable] }
      end

      context 'when variant is not purchasable' do
        before { variant.stock_items.clear }

        it { expect(described_class.with_purchasable_variant).to be_empty }
      end
    end
  end

  describe 'state machine' do
    describe '#queue!' do
      let(:request) { create :stock_request }

      it 'transitions from requested to queued' do
        expect { request.queue! }.to change(request, :state).from('requested').to 'queued'
      end
    end

    describe '#notify!' do
      let(:queued_request) { create :stock_request, state: :queued }
      let(:mailer) { instance_double ActionMailer::MessageDelivery, deliver_later: true }

      before { allow(Spree::UserMailer).to receive(:back_in_stock).and_return mailer }

      it 'transitions from queued to notified' do
        expect { queued_request.notify! }.to change(queued_request, :state).from('queued').to 'notified'
      end

      it 'sets sent_at', freeze_time: true do
        expect { queued_request.notify! }.to change(queued_request, :sent_at).from(nil).to Time.current
      end

      it 'sends a notification' do
        queued_request.notify!
        expect(Spree::UserMailer).to have_received(:back_in_stock).with queued_request
        expect(mailer).to have_received :deliver_later
      end
    end
  end
end
