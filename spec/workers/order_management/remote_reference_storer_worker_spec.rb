# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::RemoteReferenceStorerWorker do
    describe '#perform' do
    subject(:perform) { described_class.new.perform(entity_external_id, entity_remote_id) }

    let(:entity) { OrderManagement::Entity.create!(order_manageable: order_manageable) }
    let(:order_manageable) { create(:offer_settings) }
    let(:entity_remote_id) { 'remote_refrence_id' }

    context 'when given valid external_id' do
      let(:entity_external_id) { entity.external_id }

      it 'stores the entity_remote_id' do
        expect { perform }.to change { entity.reload.order_management_entity_ref }.from(nil).to(entity_remote_id)

      end
    end

    context 'when given invalid external_id' do
      let(:entity_external_id) { 'fake_one' }

      it 'does not store the entity_remote_id' do
        expect { perform }.not_to(change { entity.reload.order_management_entity_ref })
      end
    end
  end
end
