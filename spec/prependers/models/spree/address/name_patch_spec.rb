# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Address::NamePatch do
  let(:described_class) { Spree::Address }

  context 'when saving a record' do
    context 'when the `name` field is not explicitly set' do
      let(:address) { build :address, name: nil, firstname: 'John', lastname: 'Doe' }

      it 'sets `name` from `firstname` and `lastname`' do
        expect { address.save }.to change { address.read_attribute(:name) }.from(nil).to('John Doe')
      end
    end
  end

  describe '#name=' do
    let(:address) { described_class.new(firstname: 'Michael J.', lastname: 'Jackson') }

    context 'when value is nil' do
      it "doesn't update firstname and lastname" do
        address.name = nil

        expect(address.firstname).to eq('Michael J.')
        expect(address.lastname).to eq('Jackson')
      end
    end

    context 'when value is the same as firstname and lastname combined' do
      it "doesn't update firstname and lastname" do
        address.name = 'Michael J. Jackson'

        expect(address.firstname).to eq('Michael J.')
        expect(address.lastname).to eq('Jackson')
      end
    end

    context 'when value is different from firstname and lastname combined' do
      it 'updates firstname and lastname' do
        address.name = 'John Doe'

        expect(address.firstname).to eq('John')
        expect(address.lastname).to eq('Doe')
      end
    end
  end
end
