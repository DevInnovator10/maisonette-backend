# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::User::Address, type: :model do
  let(:described_class) { Spree::User }

  describe 'bill_address_attributes=' do
    subject(:bill_address_attributes) { user.bill_address_attributes = attributes }

    let(:attributes) { { 'address1' => '55 Washington Street' } }
    let(:user) { described_class.new }
    let(:bill_address) { instance_double Spree::Address }
    let(:new_bill_address) { instance_double Spree::Address, :skip_state_validation= => true }

    before do
      allow(user).to receive(:bill_address).and_return(bill_address)
      allow(user).to receive(:bill_address=).and_return(bill_address)
      allow(Spree::Address).to receive(:immutable_merge).and_return(new_bill_address)

      bill_address_attributes
    end

    it 'calls Spree::Address.immutable_merge' do
      expect(Spree::Address).to have_received(:immutable_merge).with(bill_address, attributes)
    end

    it 'saves the new bill address to the user' do
      expect(user).to have_received(:bill_address=).with(new_bill_address)
    end

    it 'returns the attributes' do
      expect(bill_address_attributes).to eq attributes
    end

    it 'flags the address as a billing address' do
      expect(new_bill_address).to have_received(:skip_state_validation=).with(true)
    end
  end

  describe '#save_in_address_book' do
    let!(:user) { create(:user) }

    context 'when saving a default address' do
      subject(:save_in_address_book) { user.save_in_address_book(address.attributes, true) }

      let(:user_address) { user.user_addresses.find_first_by_address_values(address.attributes) }

      context 'when the address is a new record' do
        let(:address) { build(:address) }

        it 'creates a new Address' do
          expect { save_in_address_book }.to change { Spree::Address.count }.by(1)
        end

        it 'creates a UserAddress' do
          expect { save_in_address_book }.to change { Spree::UserAddress.count }.by(1)
        end

        it 'sets the UserAddress default flag to true' do
          save_in_address_book
          expect(user_address.default).to eq true
        end

        it "adds the address to the user's the associated addresses" do
          expect { save_in_address_book }.to change { user.reload.addresses.count }.by(1)
        end
      end

      context 'when user already has a default address' do
        let(:address) { create(:address) }
        let(:original_default_address) { create(:ship_address) }
        let(:original_user_address) do
          user.user_addresses.find_first_by_address_values(original_default_address.attributes)
        end

        before do
          user.user_addresses.create(address: original_default_address, default: true)
        end

        it 'makes all the other associated addresses not be the default' do
          expect { save_in_address_book }.to change { original_user_address.reload.default }.from(true).to(false)
        end

        context 'when an odd flip-flop corner case discovered running backfill rake task' do
          before do
            user.save_in_address_book(original_default_address.attributes, true)
            user.save_in_address_book(address.attributes, true)
          end

          it 'handles setting 2 addresses as default without a reload of user' do
            user.save_in_address_book(original_default_address.attributes, true)
            user.save_in_address_book(address.attributes, true)
            expect(user.addresses.count).to eq 2
            expect(user.default_address.address1).to eq address.address1
          end
        end
      end

      context 'when changing existing address to default' do
        let(:address) { create(:address) }

        before do
          user.user_addresses.create(address: address, default: false)
        end

        it 'properly sets the default flag' do
          expect(save_in_address_book).to eq user.default_address
        end

        context 'when changing another address field at the same time' do
          subject(:save_in_address_book) { user.save_in_address_book(updated_address_attributes, true) }

          let(:updated_address_attributes) { address.attributes.tap { |a| a[:first_name] = 'Newbie' } }

          it 'changes first name' do
            expect(save_in_address_book.first_name).to eq updated_address_attributes[:first_name]
          end

          it 'preserves last name' do
            expect(save_in_address_book.last_name).to eq address.last_name
          end

          it 'is a new immutable address instance' do
            expect(save_in_address_book.id).not_to eq address.id
          end

          it 'is the new default' do
            expect(save_in_address_book).to eq user.default_address
          end
        end
      end

      context 'when the address is has no state' do
        let(:address) { build(:address) }

        before do
          address.country.update(states_required: true)

          address.state = nil
          address.state_name = nil
        end

        it 'creates a new Address and skips state validation' do
          expect { save_in_address_book }.to change { Spree::Address.count }.by(1)
        end
      end
    end

    context 'when updating an address and making default at once' do
      let(:address1) { create(:address) }
      let(:address2) { create(:address, firstname: 'Different') }
      let(:updated_attrs) do
        address2.attributes.tap { |a| a[:firstname] = 'Johnny' }
      end

      before do
        user.save_in_address_book(address1.attributes, true)
        user.save_in_address_book(address2.attributes, false)
      end

      it 'returns the edit as the first address' do
        user.save_in_address_book(updated_attrs, true)
        expect(user.user_addresses.first.address.firstname).to eq 'Johnny'
      end
    end

    context 'when saving a non-default address' do
      subject(:save_in_address_book) { user.save_in_address_book(address.attributes) }

      let(:user_address) { user.user_addresses.find_first_by_address_values(address.attributes) }

      context 'when the address is a new record' do
        let(:address) { build(:address) }

        it 'creates a new Address' do
          expect { save_in_address_book }.to change { Spree::Address.count }.by(1)
        end

        it 'creates a UserAddress' do
          expect { save_in_address_book }.to change { Spree::UserAddress.count }.by(1)
        end

        context 'when it is not the first address' do
          before { user.user_addresses.create!(address: create(:address)) }

          it 'sets the UserAddress default flag to false' do
            expect { save_in_address_book }.to change { Spree::UserAddress.count }.by(1)
            expect(user_address.default).to eq false
          end
        end

        context 'when it is the first address' do
          it 'sets the UserAddress default flag to true' do
            save_in_address_book
            expect(user_address.default).to eq true
          end
        end

        it "adds the address to the user's the associated addresses" do
          expect { save_in_address_book }.to change { user.reload.addresses.count }.by(1)
        end
      end
    end

    context 'when resurrecting a previously saved (but now archived) address' do
      subject(:save_in_address_book) { user.save_in_address_book(address.attributes, true) }

      let(:address) { create(:address) }

      before do
        user.save_in_address_book(address.attributes, true)
        user.remove_from_address_book(address.id)
      end

      it 'returns the address' do
        expect(save_in_address_book).to eq address
      end

      it 'sets it as default' do
        save_in_address_book
        expect(user.default_address).to eq address
      end

      context 'when an edit to another address' do
        subject(:save_in_address_book) { user.save_in_address_book(edited_attributes) }

        let(:address2) { create(:address, firstname: 'Different') }
        let(:edited_attributes) do
          # conceptually edit address2 to match the values of address
          edited_attributes = address.attributes
          edited_attributes[:id] = address2.id
          edited_attributes
        end

        before { user.save_in_address_book(address2.attributes, true) }

        it 'returns the address' do
          expect(save_in_address_book).to eq address
        end

        it 'archives address2' do
          save_in_address_book
          user_address2 = user.user_addresses.all_historical.find_by(address_id: address2.id)
          expect(user_address2.archived).to be true
        end

        context 'when a new address that matches an archived one' do
          subject(:save_in_address_book) { user.save_in_address_book(added_attributes) }

          let(:added_attributes) do
            added_attributes = address.attributes
            added_attributes.delete(:id)
            added_attributes
          end

          it 'returns the address' do
            expect(save_in_address_book).to eq address
          end

          it 'no longer has archived user_addresses' do
            save_in_address_book
            expect(user.user_addresses.all_historical).to eq user.user_addresses
          end
        end
      end
    end
  end
end
