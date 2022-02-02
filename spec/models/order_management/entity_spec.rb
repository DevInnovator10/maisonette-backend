# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::Entity, type: :model do
  it { is_expected.to belong_to(:order_manageable) }
  it { is_expected.to belong_to(:parent).optional }
  it { is_expected.to have_many(:children) }
  it {
    is_expected.to(define_enum_for(:sync_status).with_values(
                     out_of_sync: 1,
                     processing: 2,
                     in_sync: 3,
                     waiting_parent_forward: 4
                   ))
  }
  it { is_expected.to(define_enum_for(:last_result).with_values(success: 1, failed: 2)) }

  describe '.order_manageable' do
    context 'when order_manageable is discarded' do
      let(:discarded_offer_settings) { create(:offer_settings, discarded_at: Time.current) }
      let(:entity) { create(:order_management_product, order_manageable: discarded_offer_settings) }

      it 'returns the order_manageable anyway' do
        expect(entity.order_manageable).to eq discarded_offer_settings
      end
    end
  end

  describe '.parent_entity' do
    subject(:parent_entity) do
      described_class.parent_entity(nil)
    end

    it { is_expected.to be_nil }
  end

  describe '.advisory_lock_key' do
    subject(:advisory_lock_key) do
      described_class.advisory_lock_key(target_object)
    end

    let(:target_object) { build_stubbed(:offer_settings, id: 1) }
    let(:key) { "handle_record_sync_status #{described_class} Spree::OfferSettings#1" }

    it 'returns a string containing the object class name and id' do
      expect(advisory_lock_key).to eq key
    end
  end

  describe '.advisory_lock' do
    subject(:advisory_lock) do
      described_class.advisory_lock(target_object)
    end

    let(:target_object) { build_stubbed(:offer_settings, id: 1) }
    let(:key) { "handle_record_sync_status #{described_class} Spree::OfferSettings#1" }

    before do
      allow(described_class).to receive(:with_advisory_lock).with(key)
    end

    it 'wraps with with_advisory_lock method' do
      advisory_lock

      expect(described_class).to have_received(:with_advisory_lock).with(key)
    end
  end

  describe '.mark_out_of_sync!' do
    let!(:offer_settings) { create(:offer_settings) }

    context 'when no parent' do
      subject(:mark_out_of_sync!) do
        described_class.mark_out_of_sync!(offer_settings)
      end

      it 'creates a new entity' do
        described_class.find_by(order_manageable: offer_settings).destroy

        expect { mark_out_of_sync! }.to change(described_class, :count)
        new_entity = described_class.find_by(order_manageable: offer_settings)

        expect(new_entity).to be_out_of_sync
        expect(new_entity.order_manageable_type).to eq 'Spree::OfferSettings'
        expect(new_entity.order_manageable_id).to eq offer_settings.id.to_s
      end

      context 'when entity is not persisted' do
        before { allow(offer_settings).to receive(:persisted?).and_return(false) }

        it "doesn't create the new entity" do
          expect { mark_out_of_sync! }.not_to change(described_class, :count)
        end
      end
    end

    context 'when parent is forwarded' do
      subject(:mark_out_of_sync!) do
        described_class.mark_out_of_sync!(offer_settings)
      end

      let(:parent_entity) { create(:order_management_product, order_management_entity_ref: '123') }

      it 'creates a new entity' do
        described_class.find_by(order_manageable: offer_settings).destroy

        expect { mark_out_of_sync! }.to change(described_class, :count)
        new_entity = described_class.find_by(order_manageable: offer_settings)

        expect(new_entity).to be_out_of_sync
        expect(new_entity.order_manageable_type).to eq 'Spree::OfferSettings'
        expect(new_entity.order_manageable_id).to eq offer_settings.id.to_s
      end
    end

    context 'when parent is not forwarded' do
      subject(:mark_out_of_sync!) do
        described_class.mark_out_of_sync!(offer_settings)
      end

      let(:parent_entity) { create(:order_management_product, order_management_entity_ref: nil) }

      before do
        allow(described_class).to receive(:parent_entity).with(offer_settings).and_return(
          parent_entity
        )
      end

      it 'creates a new entity with state waiting_parent_forward' do
        described_class.find_by(order_manageable: offer_settings).destroy

        expect { mark_out_of_sync! }.to change(described_class, :count)
        new_entity = described_class.find_by(order_manageable: offer_settings)
        expect(new_entity).to be_waiting_parent_forward
        expect(new_entity.order_manageable_type).to eq 'Spree::OfferSettings'
        expect(new_entity.order_manageable_id).to eq offer_settings.id.to_s
        expect(new_entity.parent).to eq parent_entity
      end
    end
  end

  describe '.order_management_object_name' do
    subject(:order_management_object_name) do
      described_class.order_management_object_name
    end

    context 'when not overridden from the base class' do
      it 'raise an exception' do
        expect { order_management_object_name }.to raise_error('Define the order management object name')
      end
    end
  end

  describe '.payload_presenter_class' do
    subject(:payload_presenter_class) do
      described_class.payload_presenter_class
    end

    context 'when not overridden from the base class' do
      it 'raise an exception' do
        expect { payload_presenter_class }.to raise_error('Presenter class is not defined')
      end
    end
  end

  describe '.sync_enabled?' do
    subject(:sync_enabled?) { described_class.sync_enabled? }

    let(:oms_sync_enabled) { true }
    let(:entity_oms_sync_enabled) { true }

    before do
      allow(Flipper).to receive(:enabled?).with(:oms_sync).and_return(oms_sync_enabled)
      allow(Flipper).to receive(:enabled?).with('oms_sync_order_management/entity').and_return(entity_oms_sync_enabled)
    end

    it 'returns true' do
      expect(sync_enabled?).to be_truthy
    end

    context 'when oms_sync is disabled' do
      let(:oms_sync_enabled) { false }

      it { is_expected.to be_falsey }
    end

    context 'when oms_sync is disabled for entity class' do
      let(:entity_oms_sync_enabled) { false }

      it { is_expected.to be_falsey }
    end
  end

  describe '#payload' do
    let(:described_instance) { described_class.new }
    # rubocop:disable RSpec/VerifiedDoubles
    let(:presenter_instance) { double(:presenter_instance, payload: { a: 1, b: 2 }) }
    let(:presenter_class) { double(:presenter_class) }
    # rubocop:enable RSpec/VerifiedDoubles
    let(:order_manageable) { build_stubbed(:offer_settings) }

    before do
      allow(described_class).to receive(:payload_presenter_class).and_return(presenter_class)
      allow(presenter_class).to receive(:new).with(order_manageable).and_return(presenter_instance)
      allow(described_instance).to receive(:order_manageable).and_return(order_manageable)
    end

    it 'returns an hash' do
      expect(described_instance.payload).to eq('a' => 1, 'b' => 2)
    end
  end

  describe '#payload_for_oms_csv' do
    # rubocop:disable RSpec/VerifiedDoubles
    let(:presenter_class) { double(:presenter_class) }
    let(:presenter_instance) { double(:presenter_instance, payload: { a: 1, b: 2 }) }
    let(:described_instance) { described_class.new }
    let(:order_manageable) { build_stubbed(:offer_settings) }
    # rubocop:enable RSpec/VerifiedDoubles

    before do
      allow(described_instance).to receive(:order_manageable).and_return(order_manageable)
      allow(described_instance.class).to receive(:payload_presenter_class).and_return(presenter_class)
      allow(presenter_class).to receive(:new).with(order_manageable).and_return(presenter_instance)
    end

    it 'returns an hash' do
      expect(described_instance.payload_for_oms_csv).to eq('a' => 1, 'b' => 2)
    end
  end

  describe '#update_order_managament_ref_after_sync' do
    let(:order_manageable) { create(:offer_settings) }
    let(:child_order_manageable) { create(:offer_settings) }
    let(:remote_refrence_id) { 'my_remote_ref' }
    # rubocop:disable RSpec/VerifiedDoubles
    let(:presenter_class) { double(:presenter_class) }
    let(:presenter_instance) { double(:presenter_instance, payload: { a: 1, b: 2 }) }
    # rubocop:enable RSpec/VerifiedDoubles
    let(:described_instance) do
      main_instance = described_class.create!(order_manageable: order_manageable, last_result: :failed,
                                              last_message: 'error occured', last_request_payload: { c: 3 })
      described_class.create!(order_manageable: child_order_manageable, parent: main_instance, sync_status: 'in_sync')
      main_instance
    end

    before do
      allow(presenter_class).to receive(:new).with(order_manageable).and_return(presenter_instance)
      allow(described_instance.class).to receive(:payload_presenter_class).and_return(presenter_class)
      described_instance.update_order_managament_ref_after_sync(remote_refrence_id)
    end

    it 'changes order_management_entity_ref' do
      expect(described_instance.reload.order_management_entity_ref).to eq(remote_refrence_id)
    end

    it 'changes sync_status' do
      expect(described_instance.reload.sync_status).to eq('in_sync')
    end

    it 'changes last_result' do
      expect(described_instance.reload.last_result).to eq('success')
    end

    it 'changes last_message' do
      expect(described_instance.reload.last_message).to eq(nil)
    end

    it 'changes last_request_payload' do
      expect(described_instance.reload.last_request_payload).to eq('a' => 1, 'b' => 2)
    end

    it 'changes children sync_status' do
      expect(described_instance.reload.children.pluck(:sync_status).uniq).to eq(['out_of_sync'])
    end
  end

  describe '#external_id' do
    let(:described_instance) { described_class.create!(order_manageable: create(:offer_settings)) }
    let(:gid) { described_instance.to_gid_param }

    it 'return an hash' do
      expect(described_instance.external_id).to eq(gid)
    end

    it 'return a string that would be reverted and will return the original object' do
      expect(GlobalID::Locator.locate(described_instance.external_id)).to eq(described_instance)
    end
  end

  describe '#perform_remote_upsert!' do
    subject(:perform_remote_upsert!) { described_instance.perform_remote_upsert! }

    let(:described_instance) { described_class.new }
    # rubocop:disable RSpec/VerifiedDoubles
    let(:presenter_instance) { double(:presenter_instance, payload: {}) }
    let(:presenter_class) { double(:presenter_class, new: presenter_instance) }
    # rubocop:enable RSpec/VerifiedDoubles

    before do
      allow(described_class).to receive(:order_management_object_name).and_return('Product')
      allow(OrderManagement::ClientInterface).to receive(:upsert!).with(
        'Product', 'External_ID__c', 'External_ID__c': 'test'
      )
      allow(described_instance).to receive(:payload).and_return({})
      allow(described_instance).to receive(:external_id).and_return('test')
      allow(described_class).to receive(:sync_enabled?).and_return(true)
    end

    it 'calls the OrderManagement::ClientInterface instance' do
      perform_remote_upsert!

      expect(OrderManagement::ClientInterface).to have_received(:upsert!).with(
        'Product', 'External_ID__c',
        'External_ID__c': 'test'
      )
    end
  end

  describe '#sync_order_management!' do
    let(:described_instance) { described_class.create(sync_status: status) }
    let(:status) { 'out_of_sync' }

    before do
      allow(OrderManagement::SyncEntityWorker).to receive(:perform_async).with(described_instance.id)
    end

    context 'when entity is processing' do
      let(:status) { 'processing' }

      it 'does not call OrderManagement::SyncEntityWorker' do
        described_instance.sync_order_management!

        expect(OrderManagement::SyncEntityWorker).not_to have_received(:perform_async)
      end
    end

    context 'when entity is waiting_parent_forward' do
      let(:status) { 'waiting_parent_forward' }

      it 'does not call OrderManagement::SyncEntityWorker' do
        described_instance.sync_order_management!

        expect(OrderManagement::SyncEntityWorker).not_to have_received(:perform_async)
      end
    end

    context 'when parent has not been forwarded' do
      before do
        described_instance.parent = OrderManagement::Entity.create!(
          order_manageable: described_instance,
          order_management_entity_ref: nil
        )
      end

      it 'does not call OrderManagement::SyncEntityWorker' do
        described_instance.sync_order_management!

        expect(OrderManagement::SyncEntityWorker).not_to have_received(:perform_async)
      end
    end

    it 'calls OrderManagement::SyncEntityWorker' do
      described_instance.sync_order_management!

      expect(OrderManagement::SyncEntityWorker).to have_received(:perform_async).with(described_instance.id)
    end
  end

  describe '#forwarded?' do
    subject(:forwarded?) { entity.forwarded? }

    let(:entity) do
      OrderManagement::Entity.create!(
        order_manageable: described_class.create,
        order_management_entity_ref: '123'
      )
    end

    it { is_expected.to eq true }
  end
end
