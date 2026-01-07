# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Address::StateValidation, type: :model do
  describe 'validation' do
    let(:country) { create :country, states_required: true }
    let(:state) { Spree::State.new name: 'maryland', abbr: 'md', country: country }
    let(:address) { build(:address, country: country) }
    let(:skip_state_validation) { false }

    before do
      allow(country.states).to receive_messages with_name_or_abbr: [state]
      allow(address).to receive(:skip_state_validation).and_return(skip_state_validation)
    end

    context 'when it is a billing_address' do
      let(:skip_state_validation) { true }

      it 'allows the state_name to be anything' do
        address.state_name = 'Fake London'
        expect(address).to be_valid
      end

      it 'allows empty state and state_name' do
        address.state_name = nil
        address.state = nil
        expect(address).to be_valid
      end
    end

    context 'when address does not require state' do
      before do
        stub_spree_preferences(address_requires_state: false)
      end

      it 'address_requires_state preference is false' do
        address.state = nil
        address.state_name = nil
        expect(address).to be_valid
      end
    end

    context 'when address requires state' do
      before do
        stub_spree_preferences(address_requires_state: true)
      end

      it 'state_name is not nil and country does not have any states' do
        address.state = nil
        address.state_name = 'alabama'
        expect(address).to be_valid
      end

      it 'errors when state_name is nil' do
        address.state_name = nil
        address.state = nil
        expect(address).not_to be_valid
      end

      it 'full state name is in state_name and country does contain that state' do
        address.state_name = 'alabama'
        # called by state_validate to set up state_id.
        # Perhaps this should be a before_validation instead?
        expect(address).to be_valid
        expect(address.state).not_to be_nil
        expect(address.state_name).to be_nil
      end

      it 'state abbr is in state_name and country does contain that state' do
        address.state_name = state.abbr
        address.state = state
        expect(address).to be_valid
        expect(address.state).not_to be_nil
        expect(address.state_name).to be_nil
      end

      it 'full state name is not in state_name and country does contain that state' do
        address.state_name = 'new york'
        expect(address).to be_valid
        expect(address.state).not_to be_nil
        expect(address.state_name).to be_nil
      end

      it 'state abbr is not in state_name and country does contain that state' do
        address.state_name = 'NY'
        address.state = state
        expect(address).to be_valid
        expect(address.state).not_to be_nil
        expect(address.state_name).to be_nil
      end

      context 'when the country does not match the state' do
        context 'when the country requires states' do
          it 'is invalid' do
            address.state = state
            address.country = build(:country, states: [build(:state)])
            address.valid?
            expect(address.errors['state']).to eq(['does not match the country'])
          end
        end

        context 'when the country does not require states' do
          it 'is invalid' do
            address.state = state
            address.country = Spree::Country.new(states_required: false)
            address.valid?
            expect(address.errors['state']).to eq(['does not match the country'])
          end
        end
      end

      it 'both state and state_name are entered but country does not contain the state' do
        address.state = state
        address.state_name = 'maryland'
        address.country = create :country, states_required: true
        expect(address).to be_valid
        expect(address.state_id).to be_nil
      end

      it 'both state and state_name are entered and country does contain the state' do
        address.state = state
        address.state_name = 'maryland'
        expect(address).to be_valid
        expect(address.state_name).to be_nil
      end
    end
  end
end
