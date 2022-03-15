# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Kustomer::Entity, type: :model do
  it { is_expected.to belong_to(:kustomerable) }
  it { is_expected.to(define_enum_for(:sync_status).with_values(out_of_sync: 1, processing: 2, in_sync: 3)) }
  it { is_expected.to(define_enum_for(:last_result).with_values(success: 1, failed: 2)) }

  describe '#after_commit' do
    subject(:update_record!) { described_instance.update(attributes) }

    let(:described_instance) { described_class.create(kustomerable: order) }
    let(:order) { create(:order) }

    before do
      allow(Maisonette::Kustomer::SyncWorker).to receive(:perform_in)

      update_record!
    end

    context 'when sync_status is not updated' do
      let(:attributes) { { last_result: :failed } }

      it "doesn't sync kustomer entity" do
        expect(Maisonette::Kustomer::SyncWorker).not_to have_received(:perform_in)
      end
    end

    context 'when sync_status is not updated to out_of_sync' do
      let(:attributes) { { sync_status: :processing } }

      it "doesn't sync kustomer entity" do
        expect(Maisonette::Kustomer::SyncWorker).not_to have_received(:perform_in)
      end
    end

    context 'when sync_status is updated to out_of_sync' do
      let(:attributes) { { sync_status: 'out_of_sync' } }

      it 'synces kustomer entity' do
        expect(Maisonette::Kustomer::SyncWorker).to have_received(:perform_in).with(5.seconds, described_instance.id)
      end

      context 'when sync_status was processing' do
        let(:described_instance) { described_class.create(sync_status: 'processing') }

        it "doesn't sync kustomer entity" do
          expect(Maisonette::Kustomer::SyncWorker).not_to have_received(:perform_in)
        end
      end
    end
  end

  describe '#sync_kustomer!' do
    let(:described_instance) { described_class.create }

    before do
      allow(Maisonette::Kustomer::SyncWorker).to receive(:perform_in)
    end

    it 'syncs the entity' do
      described_instance.sync_kustomer!

      expect(Maisonette::Kustomer::SyncWorker).to have_received(:perform_in)
    end
  end

  describe '#payload' do
    let(:described_instance) { described_class.create }
    # rubocop:disable RSpec/VerifiedDoubles
    let(:presenter_instance) { double(:presenter_instance, kustomer_payload: { a: 1, b: 2 }) }
    let(:presenter_class) { double(:presenter_class, new: presenter_instance) }
    # rubocop:enable RSpec/VerifiedDoubles

    before do
      allow(described_instance).to receive(:payload_presenter_class).and_return(presenter_class)
    end

    it 'returns the hash' do
      expect(described_instance.payload).to eq(a: 1, b: 2)
    end
  end
end
