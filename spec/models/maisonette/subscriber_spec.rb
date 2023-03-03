# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Subscriber, type: :model do
  let(:subscribed) { create :subscriber }
  let(:subscribed_and_synced) { create :subscriber, :subscribed_and_synced }
  let(:unsubscribed) { create :subscriber, :unsubscribed }
  let(:unsubscribed_and_synced) { create :subscriber, :unsubscribed_and_synced }
  let(:deleted) { create :subscriber, :deleted }
  let(:deleted_and_synced) { create :subscriber, :deleted_and_synced }

  it { is_expected.to belong_to(:user).optional }

  it 'defines status enum' do
    expect(described_class.new).to(
      define_enum_for(:status).with_values(
        subscribed: 1,
        subscribed_and_synced: 2,
        unsubscribed: 3,
        unsubscribed_and_synced: 4,
        deleted: 5,
        deleted_and_synced: 6
      )
    )
  end

  describe 'validations' do
    subject { create :subscriber }

    it { is_expected.to validate_presence_of :email }
    it { is_expected.to validate_uniqueness_of(:email).scoped_to :list_id }

    describe '#email_matches_user' do
      subject(:subscriber) { described_class.new(attrs) }

      context 'without a user' do
        let(:attrs) { { email: 'foo@bar.com' } }

        it { is_expected.to be_valid }
      end

      context 'with a user' do
        let(:user) { create :user }
        let(:attrs) { { user_id: user.id } }

        context 'when not providing an email address' do
          it { is_expected.to be_valid }
        end

        context 'when providing the correct email address' do
          let(:attrs) { super().merge(email: user.email) }

          it { is_expected.to be_valid }
        end

        context 'when providing a mismatched email address' do
          let(:attrs) { super().merge(email: 'foo@bar.com') }

          it { is_expected.not_to be_valid }

          it 'has the correct error message' do
            subscriber.valid?
            expect(subscriber.errors.messages[:email]).to include 'does not match user email address'
          end
        end
      end
    end

    describe '#email_format' do
      subject(:subscriber) { described_class.new(attrs) }

      context 'when email is not a valid format' do
        let(:attrs) { { email: 'foobar' } }

        it { is_expected.not_to be_valid }
      end

      context 'when email is a valid format' do
        let(:attrs) { { email: 'foo@bar.com' } }

        it { is_expected.to be_valid }
      end
    end
  end

  describe 'scopes' do
    before do
      subscribed && subscribed_and_synced &&
        unsubscribed && unsubscribed_and_synced &&
        deleted && deleted_and_synced
    end

    it '.synced' do
      expect(described_class.synced).to match_array [subscribed_and_synced, unsubscribed_and_synced, deleted_and_synced]
    end

    it '.not_synced' do
      expect(described_class.not_synced).to match_array [subscribed, unsubscribed, deleted]
    end

    it '.with_subscription' do
      expect(described_class.with_subscription).to match_array [subscribed, subscribed_and_synced]
    end

    it '.without_subscription' do
      expect(described_class.without_subscription).to match_array [unsubscribed, unsubscribed_and_synced]
    end
  end

  describe '.unsubscribe!' do
    it 'returns nil if the subscriber is not found' do
      expect(described_class.unsubscribe!('bad_email@internet.com')).to be_nil
    end

    context 'when a subscriber is found' do
      before do
        allow(described_class).to receive(:find_by).and_return subscriber
        allow(subscriber).to receive(:unsubscribed!)

        described_class.unsubscribe! subscriber.email
      end

      context 'when subscribed' do
        let(:subscriber) { subscribed }

        it 'unsubscribes the subscriber' do
          expect(subscriber).to have_received(:unsubscribed!)
        end
      end

      context 'when subscribed and synced' do
        let(:subscriber) { subscribed_and_synced }

        it 'unsubscribes the synced subscriber' do
          expect(subscriber).to have_received(:unsubscribed!)
        end
      end

      context 'when unsubscribed' do
        let(:subscriber) { unsubscribed }

        it 'does not update the record' do
          expect(subscriber).not_to have_received(:unsubscribed!)
        end
      end

      context 'when unsubscribed and synced' do
        let(:subscriber) { unsubscribed_and_synced }

        it 'does not update the record' do
          expect(subscriber).not_to have_received(:unsubscribed!)
        end
      end
    end
  end

  describe '#subscribe_with_changes!' do
    let(:subscribed) { build_stubbed :subscriber }
    let(:subscribed_and_synced) { build_stubbed :subscriber, :subscribed_and_synced }
    let(:unsubscribed) { build_stubbed :subscriber, :unsubscribed }
    let(:unsubscribed_and_synced) { build_stubbed :subscriber, :unsubscribed_and_synced }

    before do
      [subscribed, subscribed_and_synced, unsubscribed, unsubscribed_and_synced].each do |subscriber|
        allow(subscriber).to receive(:subscribed!)
      end
    end

    it 'subscribes an unsubscribed subscriber' do
      unsubscribed.subscribe_with_changes!
      expect(unsubscribed).to have_received(:subscribed!)
    end

    it 'subscribes an unsubscribed and synced subscriber' do
      unsubscribed_and_synced.subscribe_with_changes!
      expect(unsubscribed_and_synced).to have_received(:subscribed!)
    end

    context 'when the subscriber is already subscribed' do
      context 'when no other attributes are changed on the subscriber' do
        it 'does not resubscribe the subscriber' do
          subscribed.subscribe_with_changes!
          expect(subscribed).not_to have_received(:subscribed!)
        end
      end

      context 'when other attributes are changed' do
        it 'updates the subscriber' do
          subscribed.source = 'foo'
          subscribed.subscribe_with_changes!
          expect(subscribed).to have_received(:subscribed!)
        end
      end
    end
  end

  describe '#subscription?' do
    it 'returns true if status is subscribed or subscribed_and_synced' do
      subscriber = build :subscriber
      expect(subscriber.subscription?).to be true

      subscriber = build :subscriber, :subscribed_and_synced
      expect(subscriber.subscription?).to be true

      subscriber = build :subscriber, :unsubscribed
      expect(subscriber.subscription?).to be false

      subscriber = build :subscriber, :unsubscribed_and_synced
      expect(subscriber.subscription?).to be false
    end
  end

  describe '#synced?' do
    it 'returns true if status is synced' do
      subscriber = build :subscriber, :subscribed_and_synced
      expect(subscriber.synced?).to be true

      subscriber = build :subscriber, :unsubscribed_and_synced
      expect(subscriber.synced?).to be true

      subscriber = build :subscriber, :deleted_and_synced
      expect(subscriber.synced?).to be true
    end

    it 'returns false if status is not synced' do
      subscriber = build :subscriber
      expect(subscriber.synced?).to be false

      subscriber = build :subscriber, :unsubscribed
      expect(subscriber.synced?).to be false

      subscriber = build :subscriber, :deleted
      expect(subscriber.synced?).to be false
    end
  end

  describe 'callbacks' do
    describe '#set_defaults' do
      context 'when setting the list_id' do
        let(:subscriber) { described_class.create(attrs) }
        let(:attrs) { {} }
        let(:list_id) { FFaker::Lorem.characters 6 }

        before { allow(Maisonette::Config).to receive(:fetch).with('klaviyo.default_list_id').and_return list_id }

        context 'when the list_id is not provided' do
          it 'uses the default list_id' do
            expect(subscriber.list_id).to eq list_id
          end
        end

        context 'when the list_id is provided' do
          let(:attrs) { { list_id: 'foobar' } }

          it 'does not override the list_id' do
            expect(subscriber.list_id).to eq 'foobar'
          end
        end
      end

      context 'when setting the source' do
        let(:subscriber) { described_class.create(attrs) }
        let(:attrs) { {} }

        context 'when the source is not provided' do
          it 'uses the default source' do
            expect(subscriber.source).to eq 'Registration'
          end
        end

        context 'when the source is provided' do
          let(:attrs) { { source: 'Footer' } }

          it 'does not override the source' do
            expect(subscriber.source).to eq 'Footer'
          end
        end
      end

      context 'when setting the email' do
        context 'when a user is provided' do
          let(:subscriber) { user.create_subscriber(attrs) }
          let(:user) { create :user }
          let(:attrs) { {} }

          context 'when an email is not provided' do
            it 'sets the email to the user email' do
              expect(subscriber.email).to eq user.email
            end
          end

          context 'when an email is provided' do
            let(:attrs) { { email: 'foo@bar.com' } }

            it 'does not override the provided email' do
              expect(subscriber.email).to eq 'foo@bar.com'
            end
          end
        end

        context 'when a user is not provided' do
          it 'does not set the email' do
            expect(described_class.new.email).to be_nil
          end

          it 'does not override the provided email' do
            expect(described_class.new(email: 'foo@bar.com').email).to eq 'foo@bar.com'
          end
        end
      end

      context 'when setting the user_id' do
        subject(:subscriber) { described_class.create(attrs) }

        let(:attrs) { { email: email, user_id: user.id } }
        let(:email) { user.email }
        let(:user) { create :user }

        before { allow(Spree::User).to receive(:find_by).and_call_original }

        context 'when a user_id is present' do
          it 'does not attempt to set the user_id' do
            expect(subscriber.user_id).to eq user.id
            expect(Spree::User).not_to have_received(:find_by)
          end
        end

        context 'when a user_id is not present' do
          let(:attrs) { super().except(:user_id) }

          context 'when a user with the email address exists' do
            it 'sets the correct user' do
              expect(subscriber.user_id).to eq user.id
              expect(Spree::User).to have_received(:find_by).with(email: user.email)
            end
          end

          context 'when a user with the email address does not exist' do
            let(:email) { 'foo@bar.com' }

            it 'sets the user as nil' do
              expect(subscriber.email).to eq 'foo@bar.com'
              expect(Spree::User).to have_received(:find_by).with(email: 'foo@bar.com')
              expect(subscriber.user_id).to be_nil
            end
          end
        end
      end
    end

    context 'when a record is destroyed' do
      let(:subscriber) { create :subscriber }

      before do
        allow(subscriber).to receive(:unsubscribed!)
        subscriber.destroy
      end

      it { expect(subscriber).to have_received(:unsubscribed!) }
    end

    describe '#notify_klaviyo' do
      let(:subscriber) { create :subscriber }

      before do
        subscriber
        allow(subscriber).to receive(:notify_klaviyo).and_call_original
        allow(Klaviyo::ListSubscriberWorker).to(receive(:perform_async).and_return(true))
        allow(Klaviyo::DataPrivacySubscriberWorker).to(receive(:perform_async).and_return(true))
        perform
      end

      context 'when a new record is created' do
        let(:subscriber) { build :subscriber }
        let(:perform) { subscriber.save }

        it { expect(subscriber).to have_received :notify_klaviyo }
        it { expect(Klaviyo::ListSubscriberWorker).to have_received(:perform_async).with(subscriber.id) }
      end

      context 'when updating an existing subscriber' do
        context 'when a record is subscribed and not synced' do
          let(:subscriber) { create :subscriber }

          context 'when a record is updated to synced' do
            let(:perform) { subscriber.update(status: :subscribed_and_synced) }

            it { expect(subscriber).not_to have_received :notify_klaviyo }
          end

          context 'when a record is updated to unsubscribed' do
            let(:perform) { subscriber.unsubscribed! }

            it { expect(subscriber).to have_received :notify_klaviyo }
            it { expect(Klaviyo::ListSubscriberWorker).to have_received(:perform_async).with(subscriber.id) }
          end

          context 'when a record is updated to deleted' do
            let(:perform) { subscriber.deleted! }

            it { expect(subscriber).to have_received :notify_klaviyo }
            it { expect(Klaviyo::DataPrivacySubscriberWorker).to have_received(:perform_async).with(subscriber.id) }
          end
        end

        context 'when a record is unsubscribed and not synced' do
          let(:subscriber) { create :subscriber, :unsubscribed }

          context 'when a record is updated to synced' do
            let(:perform) { subscriber.update(status: :unsubscribed_and_synced) }

            it { expect(subscriber).not_to have_received :notify_klaviyo }
          end

          context 'when a record is updated to subscribed' do
            let(:perform) { subscriber.subscribed! }

            it { expect(subscriber).to have_received :notify_klaviyo }
            it { expect(Klaviyo::ListSubscriberWorker).to have_received(:perform_async).with(subscriber.id) }
          end
        end
      end
    end
  end
end
