# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::User::Subscribers, type: :model do
  let(:described_class) { Spree::User }

  it { is_expected.to have_one(:subscriber) }

  describe 'callbacks' do
    let(:subscriber) { create :subscriber, user: user }
    let(:user) { create :user }

    describe '#before_destroy' do
      before do
        allow(subscriber).to receive(:user).and_return user
        allow(user).to receive(:unsubscribe!)
        subscriber.user.destroy
      end

      it 'unsubscribes a user before destroy' do
        expect(user).to have_received(:unsubscribe!)
      end
    end

    describe '#after_create' do
      let!(:subscriber) { create :subscriber, email: email }
      let(:email) { FFaker::Internet.email }

      it 'associates an existing subscriber' do
        user = create :user, email: email
        expect(subscriber.reload.user_id).to eq user.id
      end
    end

    describe '#after_update' do
      let(:subscriber) { create :subscriber, user: user }
      let(:user) { create :user, email: old_email }
      let(:old_email) { FFaker::Internet.email }
      let(:new_email) { FFaker::Internet.email }

      context 'when updating a user email' do
        it 'updates the existing subscriber email address' do
          expect { user.update(email: new_email) }.to change { subscriber.reload.email }.from(old_email).to new_email
        end
      end

      context 'when updating a user email with a corresponding subscriber' do
        let(:modal_subscriber) { create :subscriber, list_id: '1', user_id: nil, email: modal_email }
        let(:registration_subscriber) { create :subscriber, list_id: '1', email: registration_email }
        let(:user) { create :user, subscriber: registration_subscriber, email: registration_email }
        let(:registration_email) { 'registration@email.com' }
        let(:modal_email) { 'modal@email.com' }

        before { modal_subscriber }

        it 'updates the existing subscriber email address' do
          expect { user.update(email: modal_email) }.to change { user.reload.subscriber.email }.from(
            registration_email
          ).to(modal_email)
          expect { modal_subscriber.reload }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe '#subscribe!' do
    let(:user) { create :user }
    let(:subscriber) { create :subscriber, user: user }
    let(:unsubscribed) { create :subscriber, :unsubscribed, user: user }

    it 'creates a subscriber for a user without a subscriber' do
      expect(user.subscriber).to be_nil
      user.subscribe!
      expect(user.subscriber).not_to be_nil
      expect(user.subscriber.subscribed?).to be true
    end

    it 'subscribes an unsubscribed subscriber' do
      expect(unsubscribed.user.subscribed?).to be false
      user.subscribe!
      expect(unsubscribed.reload.subscribed?).to be true
      expect(unsubscribed.user.subscribed?).to be true
    end

    it 'does not update an already subscribed user' do
      allow(subscriber).to receive :subscribed!
      user.subscribe!
      expect(subscriber).not_to have_received :subscribed!
    end

    context 'when there is an existing subscriber with the user\'s email address' do
      let(:no_user_subscriber) { create :subscriber, status: status, email: user.email }
      let(:user) { create :user, email: email }
      let(:email) { FFaker::Internet.email }
      let(:status) { :subscribed_and_synced }

      before { no_user_subscriber.update(user: nil) }

      context 'when there is an existing subscriber with the user email' do
        it 'associates a subscriber with the user' do
          expect(user.subscriber).to be_nil
          user.subscribe!
          expect(user.reload.subscriber).to eq no_user_subscriber
        end

        context 'when the subscriber is already subscribed' do
          it 'does not change the subscription status' do
            expect(no_user_subscriber.user).to be_nil
            expect { user.subscribe! }.not_to change(no_user_subscriber.reload, :status)
            expect(user.reload.subscriber).to eq no_user_subscriber
          end
        end
      end

      context 'when the subscriber is not subscribed' do
        let(:status) { :unsubscribed }

        it 'does not subscribe the subscriber' do
          expect { user.subscribe! }.not_to change(no_user_subscriber.reload, :status)
        end
      end
    end
  end

  describe '#unsubscribe!' do
    let(:user) { create :user }
    let(:subscribed) { create :subscriber, user: user }
    let(:unsubscribed) { create :subscriber, :unsubscribed_and_synced, user: user }

    it 'does not creates a subscriber if a user does not have one already' do
      expect(user.subscriber).to be_nil
      user.unsubscribe!
      expect(user.subscriber).to be_nil
      expect(user.subscribed?).to be false
    end

    it 'unsubscribes a subscribed subscriber' do
      expect(subscribed.user.subscribed?).to be true
      user.unsubscribe!
      expect(subscribed.reload.subscribed?).to be false
      expect(subscribed.user.subscribed?).to be false
    end

    it 'does not update an already unsubscribed user' do
      expect(unsubscribed.user.subscribed?).to be false
      user.unsubscribe!
      expect(unsubscribed.reload.user.subscribed?).to be false
      expect(unsubscribed.status).to eq 'unsubscribed_and_synced'
    end
  end

  describe '#delete_subscriber!' do
    let(:user) { create :user }

    context 'when a subscriber is not deleted_synced' do
      let(:subscriber) { create :subscriber, user: user }

      it 'deletes a subscriber' do
        expect(subscriber.user.delete_subscriber!).to be true
        user.delete_subscriber!
        expect(subscriber.reload.deleted?).to be true
      end
    end

    context 'when a subscriber is deleted_synced' do
      let(:subscriber) { create :subscriber, :deleted_and_synced, user: user }

      it 'does not change the subsriber statis' do
        expect(subscriber.user.delete_subscriber!).to be true
        user.delete_subscriber!
        expect(subscriber.reload.deleted_and_synced?).to be true
      end
    end
  end

  describe '#subscribed?' do
    let(:user) { build_stubbed :user }
    let(:subscribed) { build_stubbed :subscriber, user: user }
    let(:subscribed_and_synced) { build_stubbed :subscriber, :subscribed_and_synced, user: user }
    let(:unsubscribed) { build_stubbed :subscriber, :unsubscribed, user: user }
    let(:unsubscribed_and_synced) { build_stubbed :subscriber, :unsubscribed_and_synced, user: user }

    it 'returns false if the user does not have a subscriber' do
      expect(user.subscribed?).to be false
    end

    it 'returns false if the user has an unsubscribed subscriber' do
      expect(unsubscribed.user.subscribed?).to be false
    end

    it 'returns false if the user has an unsubscribed and synced subscriber' do
      expect(unsubscribed_and_synced.user.subscribed?).to be false
    end

    it 'returns true if a user is subscribed' do
      expect(subscribed.user.subscribed?).to be true
    end

    it 'returns true if a user is subscribed and synced' do
      expect(subscribed_and_synced.user.subscribed?).to be true
    end
  end
end
